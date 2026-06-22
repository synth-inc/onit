//
//  PasteboardManager.swift
//  Onit
//
//  Centralized manager for all pasteboard interactions, including
//  programmatic insertions (Cmd+V), safe snapshot/restore, and
//  coordination with the pasteboard monitor to avoid history pollution.
//

import AppKit
import Carbon
import Foundation

@MainActor
final class PasteboardManager {
    static let shared = PasteboardManager()

    let marker = NSPasteboard.PasteboardType("com.onit.internal.pbmarker")

    struct Snapshot {
        let items: [[NSPasteboard.PasteboardType: Data]]
        let changeCount: Int
    }

    private init() {}
    
    // MARK: - Copy via Cmd+C
    
    /// Simulates Cmd+C to copy selected text, reads the result, then restores the pasteboard.
    /// - Parameter targetPid: Optional PID to send the copy command to a specific process
    /// - Parameter copyDelay: Time to wait after Cmd+C for the app to populate the pasteboard
    /// - Returns: The copied text, or nil if copy failed or no text was copied
    func copySelectedText(targetPid: pid_t? = nil, copyDelay: TimeInterval = 0.1) async -> String? {
        let pre = snapshot()
        
        // Clear pasteboard so we can detect if copy added something
        NSPasteboard.general.clearContents()
        
        // Simulate Cmd+C using combinedSessionState for better compatibility
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) else {
            restore(pre, force: true)
            return nil
        }
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) else {
            restore(pre, force: true)
            return nil
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        // Post directly to the target PID if provided
        // This sends the event to the specific app without changing activation state
        if let pid = targetPid {
            keyDown.postToPid(pid)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between key down and up
            keyUp.postToPid(pid)
        } else {
            keyDown.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between key down and up
            keyUp.post(tap: .cghidEventTap)
        }
        
        // Wait for the app to process the copy command
        try? await Task.sleep(nanoseconds: UInt64(copyDelay * 1_000_000_000))
        
        // Read the copied text
        let copiedText = NSPasteboard.general.string(forType: .string)
        
        // Restore the original pasteboard
        restore(pre, force: true)
        
        return copiedText
    }
    
    // MARK: - Insertion via Cmd+V

    @discardableResult
    func insertViaPaste(_ text: String, restoreDelay: TimeInterval = 0.25, skipInternalRestore: Bool = false) async -> Bool {
        return await insertViaPaste(text, targetPid: nil, restoreDelay: restoreDelay, skipInternalRestore: skipInternalRestore)
    }

    @discardableResult
    func insertViaPaste(_ text: String, targetPid: pid_t?, restoreDelay: TimeInterval = 0.25, skipInternalRestore: Bool = false) async -> Bool {
        let pre = snapshot()

        // Write our text with an internal marker
        setString(text, markProgrammatic: true)

        // Use the user-configured paste shortcut, falling back to Cmd+V
        let (virtualKey, pasteFlags) = Self.pasteKeyCodes()
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) else { return false }
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) else { return false }
        keyDown.flags = pasteFlags
        keyUp.flags = pasteFlags

        if let pid = targetPid {
            // Post directly to the target process, bypassing any floating windows
            keyDown.postToPid(pid)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between key down and up
            keyUp.postToPid(pid)
        } else {
            // Post to the system
            keyDown.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between key down and up
            keyUp.post(tap: .cghidEventTap)
        }

        // After a short delay, restore the original pasteboard. Callers that manage
        // their own restore (with a different snapshot) should pass skipInternalRestore=true
        // to avoid a competing restore writing the wrong content into the clipboard
        // during the window before the external restore fires.
        if !skipInternalRestore {
            let deadline = DispatchTime.now() + restoreDelay
            DispatchQueue.main.asyncAfter(deadline: deadline) { [pre] in
                Task { @MainActor in
                    self.restore(pre)
                }
            }
        }

        return true
    }

    // MARK: - Snapshot / Restore

    /// Creates a snapshot of the current pasteboard contents for later restoration
    func snapshot() -> Snapshot {
        let pb = NSPasteboard.general
        let items = (pb.pasteboardItems ?? []).map { item -> [NSPasteboard.PasteboardType: Data] in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict
        }
        return Snapshot(items: items, changeCount: pb.changeCount)
    }

    /// Restores the pasteboard to a previously saved snapshot
    func restore(_ snapshot: Snapshot, force: Bool = false) {
        let pb = NSPasteboard.general
        let currentChangeCount = pb.changeCount
        
        if !force {
            guard currentChangeCount == snapshot.changeCount ||
                  currentChangeCount == snapshot.changeCount + 1 else {
                log.warning("Snapshot restore aborted (changeCount mismatch: \(snapshot.changeCount) -> \(currentChangeCount))")
                return
            }
        }
        
        pb.clearContents()

        let restoredItems: [NSPasteboardItem] = snapshot.items.map { dict in
            let item = NSPasteboardItem()
            for (type, data) in dict {
                _ = item.setData(data, forType: type)
            }
            return item
        }

        if !restoredItems.isEmpty {
            pb.writeObjects(restoredItems)
        }

    }

    // MARK: - Paste Key Resolution

    /// Returns the virtual key code and modifier flags for the paste event.
    /// Dynamically resolves which hardware key code produces 'V' in the current
    /// keyboard layout (e.g. Dvorak maps 'V' to a different physical key than QWERTY).
    static func pasteKeyCodes() -> (CGKeyCode, CGEventFlags) {
        let vKey = keyCodeForCharacter("v") ?? CGKeyCode(0x09)
        log.info("[paste] resolved key code \(vKey) for 'V' in current layout (QWERTY default: 9)")
        return (vKey, .maskCommand)
    }

    /// Finds the hardware key code that produces the given character in the active keyboard layout.
    private static func keyCodeForCharacter(_ character: Character) -> CGKeyCode? {
        guard
            let sourceRef = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
            let dataPtr = TISGetInputSourceProperty(sourceRef, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layoutData = Unmanaged<CFData>.fromOpaque(dataPtr).takeUnretainedValue()
        let layout = CFDataGetBytePtr(layoutData)
            .withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { $0 }
        guard let target = String(character).lowercased().unicodeScalars.first?.value else { return nil }

        for keyCode in UInt16(0)..<128 {
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length = 0
            UCKeyTranslate(layout, keyCode, UInt16(kUCKeyActionDown), 0,
                           UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                           &deadKeyState, 4, &length, &chars)
            if length > 0 && UInt32(chars[0]) == target {
                return CGKeyCode(keyCode)
            }
        }
        return nil
    }

    // MARK: - Programmatic Writes

    private func setString(_ text: String, markProgrammatic: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()

        if markProgrammatic {
            let item = NSPasteboardItem()
            _ = item.setString(text, forType: .string)
            let payload = Data(("t=" + String(Date().timeIntervalSince1970)).utf8)
            _ = item.setData(payload, forType: marker)
            pb.writeObjects([item])
        } else {
            pb.declareTypes([.string], owner: nil)
            pb.setString(text, forType: .string)
        }
    }
}

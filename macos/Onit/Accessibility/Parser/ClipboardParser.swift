//
//  ClipboardParser.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import ApplicationServices.HIServices
import AppKit
import Carbon

/// Implementation of `AccessibilityParserLogic` which use the Clipboard
class ClipboardParser: AccessibilityParserLogic {
    
    private var lastParsingDate: Date?
    private var lastParsingScreen: String?

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    func parse(element: AXUIElement) -> [String: String] {
        /// Prevent the system from looping because highlighting text emits a new event.
        if let lastParsingDate = lastParsingDate,
           let lastParsingScreen = lastParsingScreen,
           Date().timeIntervalSince(lastParsingDate) < 1 {
            return [AccessibilityParsedElements.screen: lastParsingScreen]
        }
        
        let previousClipboardContent = readFromPasteboard()
        
        guard copyToClipboard() else {
            return [:]
        }
        
        deselectWithArrowKeys()
        
        let screen = readFromPasteboardWithRetry(previousContent: previousClipboardContent)
        
        restorePasteboard(content: previousClipboardContent)
        
        lastParsingDate = Date()
        lastParsingScreen = screen
        
        return [AccessibilityParsedElements.screen: screen]
    }
    
    private func copyToClipboard() -> Bool {
        guard let aKey = "a".keyCode, let cKey = "c".keyCode,
              let cmdADown = CGEvent(keyboardEventSource: nil, virtualKey: aKey, keyDown: true),
              let cmdAUp = CGEvent(keyboardEventSource: nil, virtualKey: aKey, keyDown: false),
              let cmdCDown = CGEvent(keyboardEventSource: nil, virtualKey: cKey, keyDown: true),
              let cmdCUp = CGEvent(keyboardEventSource: nil, virtualKey: cKey, keyDown: false) else {
            return false
        }

        cmdADown.flags = .maskCommand
        cmdAUp.flags = .maskCommand
        cmdCDown.flags = .maskCommand
        cmdCUp.flags = .maskCommand
        
        cmdADown.post(tap: .cghidEventTap)
        cmdAUp.post(tap: .cghidEventTap)
        
        usleep(1000)
        
        cmdCDown.post(tap: .cghidEventTap)
        cmdCUp.post(tap: .cghidEventTap)
        
        return true
    }
    
//    private func deselectWithEscape() {
//        let escapeDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(53), keyDown: true)
//        let escapeUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(53), keyDown: false)
//        
//        escapeDown?.post(tap: .cghidEventTap)
//        escapeUp?.post(tap: .cghidEventTap)
//    }
    
    private func deselectWithArrowKeys() {
        let leftKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(123), keyDown: true)
        let leftKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(123), keyDown: false)
        
        let rightKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(124), keyDown: true)
        let rightKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(124), keyDown: false)
        
        leftKeyDown?.post(tap: .cghidEventTap)
        leftKeyUp?.post(tap: .cghidEventTap)
        
        usleep(1000)
        
        rightKeyDown?.post(tap: .cghidEventTap)
        rightKeyUp?.post(tap: .cghidEventTap)
    }
    
//    private func clickAt(position: CGPoint) {
//        let mouseDown = CGEvent(
//            mouseEventSource: nil,
//            mouseType: .leftMouseDown,
//            mouseCursorPosition: position,
//            mouseButton: .left
//        )
//        
//        let mouseUp = CGEvent(
//            mouseEventSource: nil,
//            mouseType: .leftMouseUp,
//            mouseCursorPosition: position,
//            mouseButton: .left
//        )
//        
//        mouseDown?.post(tap: .cghidEventTap)
//        usleep(1000)
//        mouseUp?.post(tap: .cghidEventTap)
//    }
    
    private func readFromPasteboard() -> String {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) ?? ""
    }
    
    private func readFromPasteboardWithRetry(previousContent: String, maxAttempts: Int = 10, initialDelay: UInt32 = 50000) -> String {
        var content = ""
        var attempts = 0
        
        usleep(initialDelay)
        content = readFromPasteboard()
        
        while (content == previousContent || content.isEmpty) && attempts < maxAttempts {
            let delay = initialDelay * UInt32(attempts + 2)
            usleep(delay)
            
            let newContent = readFromPasteboard()
            if newContent != previousContent && !newContent.isEmpty {
                content = newContent
                break
            }
            
            attempts += 1
        }
        
        if content == previousContent {
            return ""
        }
        
        return content
    }
    
    private func restorePasteboard(content: String) {
        if content.isEmpty {
            return
        }
        
        let pasteboard = NSPasteboard.general
        
        pasteboard.clearContents()
        
        if !pasteboard.setString(content, forType: .string) {
            log.error("Failed to restore the pasteboard content")
        } else {
            let restored = pasteboard.string(forType: .string)
            
            if restored != content {
                log.error("Restored content does not match the original content")
            }
        }
    }
}

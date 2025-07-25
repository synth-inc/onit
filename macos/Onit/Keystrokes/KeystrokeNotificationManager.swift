//
//  KeystrokeNotificationManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/24/25.
//

import Foundation
import AppKit
import ApplicationServices

// MARK: - Keystroke Event Info

struct KeystrokeEvent {
    let type: CGEventType
    let keyCode: Int64
    let flags: CGEventFlags
    let modifierStates: (command: Bool, control: Bool, shift: Bool, option: Bool)
}

// MARK: - Keystroke Notification Manager

@MainActor
final class KeystrokeNotificationManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = KeystrokeNotificationManager()

    // MARK: - Properties

    private nonisolated(unsafe) var eventTap: CFMachPort?
    private nonisolated(unsafe) var runLoopSource: CFRunLoopSource?

    private var isCommandPressed: Bool = false
    private var isControlPressed: Bool = false
    private var isShiftPressed: Bool = false
    private var isOptionPressed: Bool = false

    private var isMonitoring: Bool = false

    // MARK: - Delegates

    private var delegates = NSHashTable<AnyObject>.weakObjects()

    func addDelegate(_ delegate: KeystrokeNotificationDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: KeystrokeNotificationDelegate) {
        delegates.remove(delegate)
    }

    private func notifyDelegates(_ notification: (KeystrokeNotificationDelegate) -> Void) {
        for case let delegate as KeystrokeNotificationDelegate in delegates.allObjects {
            notification(delegate)
        }
    }

    // MARK: - Callbacks

    private var keystrokeCallbacks: [(KeystrokeEvent) -> Void] = []

    // MARK: - Private initializer

    private init() { }

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else {
            print("KeystrokeNotificationManager: Already monitoring")
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }

                let manager = Unmanaged<KeystrokeNotificationManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handleKeyboardEvent(type: type, event: event)

                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("KeystrokeNotificationManager: Failed to create event tap")
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isMonitoring = true
        print("KeystrokeNotificationManager: Keyboard monitoring started")
    }

    func stopMonitoring() {
        guard isMonitoring else {
            print("KeystrokeNotificationManager: Not monitoring")
            return
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

            self.eventTap = nil
            self.runLoopSource = nil
        }

        isMonitoring = false
        print("KeystrokeNotificationManager: Keyboard monitoring stopped")
    }

    func addKeystrokeCallback(_ callback: @escaping (KeystrokeEvent) -> Void) {
        keystrokeCallbacks.append(callback)
    }

    func removeAllCallbacks() {
        keystrokeCallbacks.removeAll()
    }

    // MARK: - Private Methods

    private func handleKeyboardEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .flagsChanged:
            updateModifierKeys(event: event)
        case .keyDown:
            handleKeyDown(event: event)
        case .tapDisabledByUserInput:
            restartEventTapIfNeeded()
        case .tapDisabledByTimeout:
            restartEventTapIfNeeded()
        default:
            break
        }
    }

    private func restartEventTapIfNeeded() {
        if let eventTap = self.eventTap {
            DispatchQueue.main.async {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }
    }

    private func updateModifierKeys(event: CGEvent) {
        let flags = event.flags
        isCommandPressed = flags.contains(.maskCommand)
        isControlPressed = flags.contains(.maskControl)
        isShiftPressed = flags.contains(.maskShift)
        isOptionPressed = flags.contains(.maskAlternate)
    }

    private func handleKeyDown(event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let modifierStates = (command: isCommandPressed, control: isControlPressed, shift: isShiftPressed, option: isOptionPressed)


        let keystrokeEvent = KeystrokeEvent(
            type: .keyDown,
            keyCode: keyCode,
            flags: flags,
            modifierStates: modifierStates
        )

        // Notify all callbacks
        notifyDelegates { delegate in
            delegate.keystrokeNotificationManager(self, didReceiveKeystroke: keystrokeEvent)
        }
    }

    // MARK: - Utility Methods

    func getCurrentModifierStates() -> (command: Bool, control: Bool, shift: Bool, option: Bool) {
        return (command: isCommandPressed, control: isControlPressed, shift: isShiftPressed, option: isOptionPressed)
    }
}

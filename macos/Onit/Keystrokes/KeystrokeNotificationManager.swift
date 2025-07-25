//
//  KeystrokeNotificationManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/24/25.
//

import Foundation
import AppKit

// MARK: - Keystroke Notification Manager
@MainActor
final class KeystrokeNotificationManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = KeystrokeNotificationManager()

    // MARK: - Properties

    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

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

    // MARK: - Private initializer

    private init() {
        startMonitoring()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else { return }

        // Monitor key down events
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyboardEvent(event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyboardEvent(event)
        }

        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else {
            return
        }

        if let localEventMonitor = localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }

        isMonitoring = false
    }

    // MARK: - Private Methods

    private func handleKeyboardEvent(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            updateModifierKeys(event: event)
        case .keyDown:
            handleKeyDown(event: event)
        default:
            break
        }
    }

    private func updateModifierKeys(event: NSEvent) {
        let flags = event.modifierFlags
        isCommandPressed = flags.contains(.command)
        isControlPressed = flags.contains(.control)
        isShiftPressed = flags.contains(.shift)
        isOptionPressed = flags.contains(.option)
    }

    private func handleKeyDown(event: NSEvent) {
        // Notify all callbacks
        notifyDelegates { delegate in
            delegate.keystrokeNotificationManager(self, didReceiveKeystroke: event)
        }
    }

    // MARK: - Utility Methods

    func getCurrentModifierStates() -> (command: Bool, control: Bool, shift: Bool, option: Bool) {
        return (command: isCommandPressed, control: isControlPressed, shift: isShiftPressed, option: isOptionPressed)
    }
}

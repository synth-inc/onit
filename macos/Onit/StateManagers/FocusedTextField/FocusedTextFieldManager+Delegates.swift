//
//  FocusedTextFieldManager+Delegates.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/29/25.
//

import ApplicationServices

extension FocusedTextFieldManager: AccessibilityNotificationsDelegate {

    var wantsNotificationsFromIgnoredProcesses: Bool { true }
    var wantsNotificationsFromOnit: Bool { true }
    
    // MARK: - AccessibilityNotificationsDelegate Implementation
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeFocusedUIElement element: AXUIElement) {
        self.handleFocusedUIElementChanged(for: element)
    }
    
    // Unused stubs
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeSelection element: AXUIElement) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

extension FocusedTextFieldManager: AccessibilityObserversDelegate {
    func accessibilityObserversManager(didActivateApplication appName: String?, processID: pid_t) {
        self.handleAppActivation(appName: appName, processID: processID)
    }
    
    func accessibilityObserversManager(didActivateOnit processID: pid_t) {
        self.handleAppActivation(appName: "Onit", processID: processID)
    }
    
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?, processID: pid_t) {
        self.handleAppActivation(appName: appName, processID: processID)
    }
    
    func accessibilityObserversManager(didDeactivateApplication appName: String?, processID: pid_t) {}
    func accessibilityObserversManager(didReceiveNotification notification: String,
                                       element: AXUIElement,
                                       elementPid: pid_t,
                                       info: [String: Any]) {}
    func accessibilityObserversManager(didDeactivateIgnoredApplication appName: String?, processID: pid_t) {}
    func accessibilityObserversManager(didDeactivateOnit processID: pid_t) {}
}

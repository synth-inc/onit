//
//  HighlightedTextManager+Delegates.swift
//  Onit
//
//  Created by TimL on 28/04/2025.
//

import ApplicationServices

extension HighlightedTextManager: AccessibilityNotificationsDelegate {
    // MARK: - AccessibilityNotificationsDelegate Implementation
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeSelection element: AXUIElement) {
        handleSelectionChange(for: element)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeFocusedUIElement element: AXUIElement) {
        handleCaretPositionChange(for: element)
    }
    
    // Unused stubs
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

extension HighlightedTextManager: AccessibilityObserversDelegate {
    
    func accessibilityObserversManager(didActivateApplication appName: String?, processID: pid_t) {
        setCurrentSource(appName)
    }
    
    func accessibilityObserversManager(didDeactivateApplication appName: String?, processID: pid_t) {
        // Reset state when app deactivates
        reset()
    }
    
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?, processID: pid_t) {}
    func accessibilityObserversManager(didReceiveNotification notification: String,
                                       element: AXUIElement,
                                       elementPid: pid_t,
                                       info: [String: Any]) {}
    func accessibilityObserversManager(didDeactivateIgnoredApplication appName: String?, processID: pid_t) {}
    func accessibilityObserversManager(didActivateOnit processID: pid_t) {}
    func accessibilityObserversManager(didDeactivateOnit processID: pid_t) {}
}

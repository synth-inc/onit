//
//  AccessibilityNotificationsDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 08/04/2025.
//

import SwiftUI

@MainActor protocol AccessibilityNotificationsDelegate: AnyObject {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateOnit window: TrackedWindow)
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow)
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow)
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow)
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeValue element: AXUIElement, newValue: String?, window: TrackedWindow?)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didFocusTextElement element: AXUIElement, window: TrackedWindow?)
}

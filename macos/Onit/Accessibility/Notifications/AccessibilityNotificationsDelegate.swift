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
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didFocusUIElement element: AXUIElement, window: TrackedWindow?)
    
    /// When true, this delegate will receive notifications from all process types,
    /// including Onit's own process and ignored applications. 
    /// Defaults to false for backwards compatibility.
    var wantsNotificationsFromAllProcesses: Bool { get }
}

// MARK: - Default Implementation

extension AccessibilityNotificationsDelegate {
    /// Default implementation returns false to maintain backwards compatibility
    var wantsNotificationsFromAllProcesses: Bool { false }
}

//
//  AccessibilityObserversDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 08/05/2025.
//

import ApplicationServices
import Foundation

@MainActor protocol AccessibilityObserversDelegate: AnyObject {
    func accessibilityObserversManager(didActivateApplication appName: String?, processID: pid_t)
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?, processID: pid_t)
    func accessibilityObserversManager(didReceiveNotification notification: String,
                                       element: AXUIElement,
                                       elementPid: pid_t,
                                       info: [String: Any])
    func accessibilityObserversManager(didDeactivateApplication appName: String?, processID: pid_t)
    func accessibilityObserversManager(didDeactivateIgnoredApplication appName: String?, processID: pid_t)

    // Note: because our OnitRegularPanel has styleMask [.nonactivatingPanel], these notifications are not always fired.
    // A click on the panel does not create a notification, but clicking the icon in Dock does.
    // These shouldn't be relied on for core logic. 
    func accessibilityObserversManager(didActivateOnit processID: pid_t)
    func accessibilityObserversManager(didDeactivateOnit processID: pid_t)
}

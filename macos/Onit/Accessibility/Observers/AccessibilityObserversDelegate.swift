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
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?)
    func accessibilityObserversManager(didReceiveNotification notification: String,
                                       element: AXUIElement,
                                       elementPid: pid_t,
                                       info: [String: Any])
    func accessibilityObserversManager(didDeactivateApplication appName: String?, processID: pid_t)
}

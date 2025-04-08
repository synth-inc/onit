//
//  AccessibilityNotificationsDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 08/04/2025.
//

import SwiftUI

@MainActor protocol AccessibilityNotificationsDelegate: AnyObject {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow)
}

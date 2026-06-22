//
//  PrivacyManager.swift
//  Onit
//
//  Created by Kévin Naudin on 10/13/2025.
//

import Foundation
import ApplicationServices
import Defaults

@MainActor
class PrivacyManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = PrivacyManager()
    
    // MARK: - Properties
    
    @Published private(set) var isCurrentWindowPrivate: Bool = false
    
    var wantsNotificationsFromIgnoredProcesses: Bool = false
    var wantsNotificationsFromOnit: Bool = false

    /// Track the current active window to compare in title change events
    private var currentActiveWindow: TrackedWindow?
    
    // MARK: - Private initialization
    
    private init() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
    
    // MARK: - Functions
    
    func shouldBlockDataCollection() -> Bool {
        guard Defaults[.sidekickDisabledInPrivateBrowser] else {
            return false
        }
        return isCurrentWindowPrivate
    }
    
    private func isPrivateBrowsingWindow(window: AXUIElement) -> Bool {
        guard let pid = window.pid(),
              let appName = pid.appName,
              let title = window.title()?.lowercased() else { return false }
        
        let keywordByApp = [
            "Google Chrome": "(Incognito)",
            "Safari": "private browsing",
            "Firefox": "private browsing",
            "Microsoft Edge": "(InPrivate)",
            "Brave Browser": "(Private)"
        ]
        
        for (app, keyword) in keywordByApp {
            if appName == app, title.contains(keyword.lowercased()) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - AccessibilityNotificationsDelegate

extension PrivacyManager: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        currentActiveWindow = window
        isCurrentWindowPrivate = isPrivateBrowsingWindow(window: window.element)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {
        if isCurrentWindowPrivate {
            isCurrentWindowPrivate = false
        }
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}

    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {
        // When a window is destroyed, check if it was the private window
        // If so, reset the state (the next window activation will set the correct state)
        if isCurrentWindowPrivate && isPrivateBrowsingWindow(window: window.element) {
            isCurrentWindowPrivate = false
        }
    }

    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}

    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {
        // Only update if this is the current active window
        // This prevents background windows from overwriting the private browsing state
        guard let activeWindow = currentActiveWindow, window == activeWindow else { return }

        // When active window title changes, re-check private browsing status
        isCurrentWindowPrivate = isPrivateBrowsingWindow(window: window.element)
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeSelection element: AXUIElement, selectedText: String?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeFocusedUIElement element: AXUIElement) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeValue element: AXUIElement) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeactivateApplication appName: String?, processID: pid_t) {}
}


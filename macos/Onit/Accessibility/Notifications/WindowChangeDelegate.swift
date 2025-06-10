//
//  WindowChangeDelegate.swift
//  Onit
//
//  Created by Assistant on 12/9/2024.
//

import Foundation
import AppKit

// MARK: - Window Change Info

struct WindowChangeInfo {
    let appBundleUrl: URL?
    let windowName: String?
    let pid: pid_t?
    let element: AXUIElement?
    let trackedWindow: TrackedWindow?
}

// MARK: - Window Change Delegate

final class WindowChangeDelegate: AccessibilityNotificationsDelegate {
    private let onWindowChange: (WindowChangeInfo) -> Void
    
    init(onWindowChange: @escaping (WindowChangeInfo) -> Void) {
        self.onWindowChange = onWindowChange
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunchedReceived),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    private static func extractWindowInfo(from trackedWindow: TrackedWindow?) -> WindowChangeInfo {
        if let trackedWindow = trackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppBundleUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName() ?? nil
            
            return WindowChangeInfo(
                appBundleUrl: windowAppBundleUrl,
                windowName: windowName,
                pid: pid,
                element: trackedWindow.element,
                trackedWindow: trackedWindow
            )
        } else {
            return WindowChangeInfo(
                appBundleUrl: nil,
                windowName: nil,
                pid: nil,
                element: nil,
                trackedWindow: nil
            )
        }
    }
    
    // Tracks when a new window is opened.
    @objc private func appLaunchedReceived(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let app = (userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) ??
                        (userInfo["NSWorkspaceApplicationKey"] as? NSRunningApplication)
        else { return }
        
        let currentAppIsXCode = app.localizedName?.lowercased() == "xcode"
        var isDev: Bool = false
        #if DEBUG
        isDev = true
        #endif
        
        let doNotTrackXCode = currentAppIsXCode && isDev
        
        // We don't want to track XCode in accessibility in DEBUG mode because it causes issues when launching Onit.
        if doNotTrackXCode {
            let windowInfo = WindowChangeInfo(
                appBundleUrl: nil,
                windowName: nil,
                pid: nil,
                element: nil,
                trackedWindow: nil
            )
            onWindowChange(windowInfo)
        } else {
            var title: String? = nil
            var appName: String? = nil
            var element: AXUIElement? = nil
            
            if let window = app.processIdentifier.firstMainWindow {
                title = window.title()
                appName = window.appName()
                element = window
            } else {
                let axElement = app.processIdentifier.getAXUIElement()
                appName = axElement.appName()
                element = axElement
            }
            
            let windowAppBundleUrl = app.bundleURL
            let windowName = title ?? appName ?? app.localizedName ?? "Unknown"
            
            let windowInfo = WindowChangeInfo(
                appBundleUrl: windowAppBundleUrl,
                windowName: windowName,
                pid: app.processIdentifier,
                element: element,
                trackedWindow: nil
            )
            
            onWindowChange(windowInfo)
        }
    }
    
    // MARK: - AccessibilityNotificationsDelegate
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow window: TrackedWindow
    ) {
        let windowInfo = Self.extractWindowInfo(from: window)
        onWindowChange(windowInfo)
    }
    
    // Tracks when changing focused sub-window in the current window (switching browser tabs, etc.).
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle window: TrackedWindow
    ) {
        let windowInfo = Self.extractWindowInfo(from: window)
        onWindowChange(windowInfo)
    }
    
    // Below is required to conform to AccessibilityNotificationsDelegate protocol but aren't needed in this implementation.
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
}
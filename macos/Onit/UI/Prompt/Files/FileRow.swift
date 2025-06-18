//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Defaults
import SwiftUI

struct FileRow: View {
    @Environment(\.windowState) var windowState
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    @State private var windowDelegate: WindowChangeDelegate? = nil
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var windowBeingAddedToContext: Bool {
        if let foregroundWindow = windowState.foregroundWindow {
            return windowState.windowContextTasks[foregroundWindow.hash] != nil
        } else {
            return false
        }
    }
    
    var windowAlreadyInContext: Bool {
        if let foregroundWindow = windowState.foregroundWindow,
           !contextList.isEmpty
        {
            let windowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            
            for contextItem in contextList {
                if case .auto(let autoContext) = contextItem {
                    if windowName == autoContext.appTitle {
                        windowState.cleanupWindowContextTask(
                            uniqueWindowIdentifier: foregroundWindow.hash
                        )
                        return true
                    }
                }
            }
            
            return false
        } else {
            return false
        }
    }
    
    var foregroundWindowName: String? {
        if let foregroundWindow = windowState.foregroundWindow,
           accessibilityEnabled,
           !(windowBeingAddedToContext || windowAlreadyInContext)
        {
            return WindowHelpers.getWindowName(window: foregroundWindow.element)
        } else {
            return nil
        }
    }
    
    var contextList: [Context]

    var body: some View {
        FlowLayout(spacing: 6) {
            PaperclipButton()
            
            addForegroundWindowToContextButton
            
            pendingAutoContextItems
            
            if !contextList.isEmpty {
                ForEach(contextList, id: \.self) { context in
                    ContextItem(item: context, isEditing: true)
                        .scrollTargetLayout()
                        .contentShape(Rectangle())
                }
            }
        }
        .onAppear {
            windowState.updateForegroundWindow()
            
            let delegate = WindowChangeDelegate(windowState: windowState)
            
            windowDelegate = delegate
            
            AccessibilityNotificationsManager.shared.addDelegate(delegate)
        }
        .onDisappear {
            windowState.cleanUpPendingWindowContextTasks()
            cleanUpWindowDelegateIfExists()
        }
    }
}

// MARK: - Child Components

extension FileRow {
    @ViewBuilder
    private var addForegroundWindowToContextButton: some View {
        if autoContextFromCurrentWindow,
           let foregroundWindow = windowState.foregroundWindow,
           let foregroundWindowName = foregroundWindowName
        {
            ContextTag(
                text: foregroundWindowName,
                hoverTextColor: .T_2,
                background: .clear,
                hoverBackground: .clear,
                hasHoverBorder: true,
                shouldFadeIn: true,
                iconBundleURL: WindowHelpers.getWindowAppBundleUrl(window: foregroundWindow.element),
                tooltip: "Add \(foregroundWindowName) Context"
            ) {
                addWindowToContext()
            }
        }
    }
    
    private var pendingAutoContextItems: some View {
        ForEach(Array(windowState.windowContextTasks.keys), id: \.self) { uniqueWindowIdentifier in
            let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.findTrackedWindow(
                trackedWindowHash: uniqueWindowIdentifier
            )
            
            if let trackedWindow = trackedWindow {
                ContextTag(
                    text: WindowHelpers.getWindowName(window: trackedWindow.element),
                    background: .clear,
                    hoverBackground: .clear,
                    isLoading: true,
                    iconView: LoaderPulse(),
                    removeAction: {
                        windowState.cleanupWindowContextTask(
                            uniqueWindowIdentifier: uniqueWindowIdentifier
                        )
                    }
                )
            }
        }
    }
}

// MARK: - Private Functions

extension FileRow {
    private func addWindowToContext() {
        if let foregroundWindow = windowState.foregroundWindow {
            windowState.addWindowToContext(
                window: foregroundWindow.element
            )
        }
    }
    
    private func cleanUpWindowDelegateIfExists() {
        if let delegate = windowDelegate {
            AccessibilityNotificationsManager.shared.removeDelegate(delegate)
        }
    }
}

// MARK: - Window Change Delegate (to track window changes)

private final class WindowChangeDelegate: AccessibilityNotificationsDelegate {
    private let windowState: OnitPanelState
    
    init(windowState: OnitPanelState) {
        self.windowState = windowState
        
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
            windowState.foregroundWindow = nil
        } else {
            let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.trackWindowForElement(
                app.processIdentifier.getAXUIElement(),
                pid: app.processIdentifier
            )
            
            windowState.foregroundWindow = trackedWindow
        }
    }
    
    private func handleUpdateForegroundWindow(_ uniqueWindowIdentifier: UInt) {
        if windowState.windowContextTasks[uniqueWindowIdentifier] == nil {
            windowState.updateForegroundWindow()
        }
    }
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow window: TrackedWindow
    ) {
        handleUpdateForegroundWindow(window.hash)
    }
    
    // Tracks when changing focused sub-window in the current window (switching browser tabs, etc.).
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle window: TrackedWindow
    ) {
        handleUpdateForegroundWindow(window.hash)
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didMinimizeWindow window: TrackedWindow
    ) {
        if windowState.foregroundWindow == window {
            windowState.foregroundWindow = nil
        } else {
            handleUpdateForegroundWindow(window.hash)
        }
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didDeminimizeWindow window: TrackedWindow
    ) {
        handleUpdateForegroundWindow(window.hash)
    }
    
    // Below is required to conform to AccessibilityNotificationsDelegate protocol but aren't needed in this implementation.
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

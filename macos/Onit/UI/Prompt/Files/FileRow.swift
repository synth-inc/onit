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
    @State private var windowAlreadyInContext: Bool = false
    
    @State private var addingAutoContext: Bool = false
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var windowName: String? {
        if accessibilityEnabled,
           !windowAlreadyInContext
        {
            return windowState.currentWindowName
        } else {
            return nil
        }
    }
    
    var appIcon: (any View)? {
        if let appBundleUrl = windowState.currentWindowAppBundleUrl {
            let iconUrl = NSWorkspace.shared.icon(forFile: appBundleUrl.path)
            
            return Image(nsImage: iconUrl)
                .resizable()
                .frame(width: 16, height: 16)
                .cornerRadius(4)
        } else {
            return nil
        }
    }
    
    var contextList: [Context]

    var body: some View {
        FlowLayout(spacing: 6) {
            PaperclipButton(
                currentWindowBundleUrl: windowState.currentWindowAppBundleUrl,
                currentWindowName: windowState.currentWindowName,
                currentWindowPid: windowState.currentWindowPid
            )
            
            if autoContextFromCurrentWindow,
               let windowName = windowName
            {
                ContextTag(
                    text: windowName,
                    hoverTextColor: .T_2,
                    background: .clear,
                    hoverBackground: .clear,
                    hasHoverBorder: true,
                    shouldFadeIn: true,
                    iconBundleURL: windowState.currentWindowAppBundleUrl,
                    tooltip: "Add \(windowName) Context"
                ) {
                    addWindowToContext()
                }
            }
            
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
            initializeCurrentWindowInfo()
            
            let delegate = WindowChangeDelegate(windowState: windowState)
            
            windowDelegate = delegate
            
            AccessibilityNotificationsManager.shared.addDelegate(delegate)
        }
        .onDisappear {
            cleanUpPendingAutoContextTasks()
            cleanUpWindowDelegateIfExists()
        }
        .onChange(of: windowState.currentWindowName) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: contextList) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: windowState.addAutoContextTasks) { _, _ in
            if let windowName = windowState.currentWindowName,
               let _ = windowState.addAutoContextTasks[windowName]
            {
                windowAlreadyInContext = true
            }
            
            addingAutoContext = !windowState.addAutoContextTasks.isEmpty
        }
    }
}

// MARK: - Child Components

extension FileRow {
    private var pendingAutoContextItems: some View {
        ForEach(Array(windowState.addAutoContextTasks.keys), id: \.self) { windowName in
            ContextTag(
                text: windowName,
                background: .clear,
                hoverBackground: .clear,
                isLoading: true,
                iconView: LoaderPulse(),
                removeAction: { deleteAutoContextTask(windowName) }
            )
        }
    }
}

// MARK: - Private Functions

extension FileRow {
    private func initializeCurrentWindowInfo() {
        let (
            currentWindowName,
            currentWindowPid,
            currentWindowAppBundleUrl
        ) = windowState.getCurrentWindowDetails()
        
        windowState.setCurrentWindowDetails(
            windowName: currentWindowName,
            windowPid: currentWindowPid,
            windowAppBundleUrl: currentWindowAppBundleUrl
        )
    }
    
    private func detectCurrentWindowAlreadyInContext() -> Bool {
        if let windowName = windowState.currentWindowName,
            !contextList.isEmpty
        {
            for context in contextList {
                if case .auto(let autoContext) = context {
                    if windowName == autoContext.appTitle {
                        deleteAutoContextTask(windowName)
                        return true
                        
                    }
                }
            }
            
            return false
        } else {
            return false
        }
    }
    
    private func addWindowToContext() {
        if let windowName = windowState.currentWindowName,
           let pid = windowState.currentWindowPid
        {
            windowState.addWindowToContext(
                windowName: windowName,
                pid: pid,
                appBundleUrl: windowState.currentWindowAppBundleUrl
            )
        }
    }
    
    private func deleteAutoContextTask(_ windowName: String) {
        windowState.addAutoContextTasks[windowName]?.cancel()
        windowState.addAutoContextTasks.removeValue(forKey: windowName)
    }
    
    private func cleanUpPendingAutoContextTasks() {
        for (_, task) in windowState.addAutoContextTasks {
            task.cancel()
        }
        
        windowState.addAutoContextTasks = [:]
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
            windowState.setCurrentWindowDetails()
        } else {
            var title: String? = nil
            var appName: String? = nil
            
            if let window = app.processIdentifier.firstMainWindow {
                title = window.title()
                appName = window.appName()
            } else {
                appName = app.processIdentifier.getAXUIElement().appName()
            }
            
            let currentWindowName = title ?? appName ?? app.localizedName ?? "Unknown"
            let currentWindowAppBundleUrl = app.bundleURL
            
            windowState.setCurrentWindowDetails(
                windowName: currentWindowName,
                windowPid: app.processIdentifier,
                windowAppBundleUrl: currentWindowAppBundleUrl
            )
        }
    }
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow window: TrackedWindow
    ) {
        let (
            currentWindowName,
            currentWindowPid,
            currentWindowAppBundleUrl
        ) = windowState.getCurrentWindowDetails()
        
        windowState.setCurrentWindowDetails(
            windowName: currentWindowName,
            windowPid: currentWindowPid,
            windowAppBundleUrl: currentWindowAppBundleUrl
        )
    }
    
    // Tracks when changing focused sub-window in the current window (switching browser tabs, etc.).
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle window: TrackedWindow
    ) {
        let (
            currentWindowName,
            currentWindowPid,
            currentWindowAppBundleUrl
        ) = windowState.getCurrentWindowDetails()
        
        windowState.setCurrentWindowDetails(
            windowName: currentWindowName,
            windowPid: currentWindowPid,
            windowAppBundleUrl: currentWindowAppBundleUrl
        )
    }
    
    // Below is required to conform to AccessibilityNotificationsDelegate protocol but aren't needed in this implementation.
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

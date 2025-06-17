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
    
    @State private var addingWindowContext: Bool = false
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var foregroundWindowName: String? {
        if let foregroundWindow = windowState.foregroundWindow,
           accessibilityEnabled,
           !windowAlreadyInContext
        {
            return windowState.getWindowName(window: foregroundWindow.element)
        } else {
            return nil
        }
    }
    
    var contextList: [Context]

    var body: some View {
        FlowLayout(spacing: 6) {
            PaperclipButton()
            
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
                    iconBundleURL: windowState.getWindowAppBundleUrl(window: foregroundWindow.element),
                    tooltip: "Add \(foregroundWindowName) Context"
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
            windowState.cleanUpPendingWindowContextTasks()
            cleanUpWindowDelegateIfExists()
        }
        .onChange(of: windowState.foregroundWindow) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: contextList) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
//        .onChange(of: windowState.windowContextTasks) { _, new in
//            if let foregroundWindow = windowState.foregroundWindow,
//               let _ = new[foregroundWindow.hash]
//            {
//                windowAlreadyInContext = true
//            }
//            
//            addingWindowContext = !new.isEmpty
//        }
    }
}

// MARK: - Child Components

extension FileRow {
    private var pendingAutoContextItems: some View {
        ForEach(Array(windowState.windowContextTasks.keys), id: \.self) { uniqueWindowIdentifier in
            if let foregroundWindowName = foregroundWindowName { // Placeholder. Still need to work this out. Should be the window task's name.
                ContextTag(
                    text: foregroundWindowName,
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
    private func initializeCurrentWindowInfo() {
        windowState.updateForegroundWindow()
    }
    
    private func detectCurrentWindowAlreadyInContext() -> Bool {
        if let foregroundWindow = windowState.foregroundWindow,
           !contextList.isEmpty
        {
            
            for context in contextList {
                if case .auto(let autoContext) = context {
                    if autoContext.appHash == foregroundWindow.hash {
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
//            windowState.foregroundWindow = app.processIdentifier.getAXUIElement()
            
            // Placeholder. Still need to work this out. Need to properly set foregroundWindow as the newly opened window.
        }
    }
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow window: TrackedWindow
    ) {
        if windowState.windowContextTasks[window.hash] == nil {
            windowState.updateForegroundWindow()
        }
    }
    
    // Tracks when changing focused sub-window in the current window (switching browser tabs, etc.).
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle window: TrackedWindow
    ) {
        if windowState.windowContextTasks[window.hash] == nil {
            windowState.updateForegroundWindow()
        }
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

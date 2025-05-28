//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct FileRow: View {
    @Environment(\.windowState) var windowState
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    @State private var currentWindowInfo: (
        appBundleUrl: URL?,
        name: String?,
        pid: pid_t?
    ) = (nil, nil, nil)
    
    @State private var windowDelegate: WindowChangeDelegate? = nil
    @State private var windowAlreadyInContext: Bool = false
    
    @State private var addingAutoContext: Bool = false
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var windowName: String? {
        if accessibilityEnabled,
           !windowAlreadyInContext,
           let windowName = currentWindowInfo.name
        {
            return windowName
        } else {
            return nil
        }
    }
    
    var appIcon: (any View)? {
        if let appBundleUrl = currentWindowInfo.appBundleUrl {
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

        VStack(alignment: .leading, spacing: 6) {
            header
            contextListRow
        }
        .onAppear {
            currentWindowInfo = initializeCurrentWindowInfo()
            
            let delegate = WindowChangeDelegate(onWindowChange: { windowInfo in
                currentWindowInfo = windowInfo
            })
            
            windowDelegate = delegate
            
            AccessibilityNotificationsManager.shared.addDelegate(delegate)
        }
        .onDisappear {
            cleanUpPendingAutoContextTasks()
            cleanUpWindowDelegateIfExists()
        }
        .onChange(of: currentWindowInfo.name) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: contextList) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: windowState.addAutoContextTasks) { _, _ in
            if let windowName = currentWindowInfo.name,
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
    private var header: some View {
        HStack(spacing: 6) {
            PaperclipButton(
                shouldShowAddContextButton: windowName == nil,
                currentWindowBundleUrl: currentWindowInfo.appBundleUrl
            )
            
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    if let windowName = windowName {
                        ContextButton(
                            text: windowName,
                            hoverTextColor: .T_2,
                            background: .clear,
                            hoverBackground: .clear,
                            hasHoverBorder: true,
                            shouldFadeIn: true,
                            icon: appIcon
                        ) {
                            addWindowToContext()
                        }
                        
//                        AutoContextButton(
//                            text: windowName,
//                            isAdd: true,
//                            appBundleUrl: currentWindowInfo.appBundleUrl
//                        ) {
//                            addWindowToContext()
//                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var pendingAutoContexts: some View {
        ForEach(Array(windowState.addAutoContextTasks.keys), id: \.self) { windowName in
            TagButton(
                text: windowName,
                maxWidth: 155,
                borderColor: .clear,
                child: LoaderPulse().padding(0).padding(.leading, 1),
                closeAction: { deleteAutoContextTask(windowName) }
            )
        }
    }
    
    private var contextListRow: some View {
        FlowLayout(spacing: 6) {
            pendingAutoContexts
            
            if !contextList.isEmpty {
                ForEach(contextList, id: \.self) { context in
                    ContextItem(item: context, isEditing: true)
                        .scrollTargetLayout()
                        .contentShape(Rectangle())
                }
            }
        }
    }
}

// MARK: - Private Functions

extension FileRow {
    static func getWindowIconAndName(_ trackedWindow: TrackedWindow?) -> (URL?, String?, pid_t?) {
        if let trackedWindow = trackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppBundleUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName() ?? nil
            
            return (windowAppBundleUrl, windowName, pid)
        } else {
            return (nil, nil, nil)
        }
    }
    
    private func initializeCurrentWindowInfo() -> (URL?, String?, pid_t?) {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        return FileRow.getWindowIconAndName(windowsManager.activeTrackedWindow)
    }
    
    private func detectCurrentWindowAlreadyInContext() -> Bool {
        if let windowName = currentWindowInfo.name, !contextList.isEmpty {
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
    
//    private func addWindowToContext() {
//        if let windowName = currentWindowInfo.name {
//            windowState.addAutoContextTasks[windowName]?.cancel()
//            
//            windowState.addAutoContextTasks[windowName] = Task {
//                PanelStateCoordinator.shared.fetchWindowContext()
//            }
//        }
//    }
    
    private func addWindowToContext() {
        if let windowName = currentWindowInfo.name,
           let pid = currentWindowInfo.pid,
           let focusedWindow = pid.firstMainWindow
        {
            windowState.addAutoContextTasks[windowName]?.cancel()
            
            windowState.addAutoContextTasks[windowName] = Task {
                let _ = AccessibilityNotificationsManager.shared.windowsManager.append(focusedWindow, pid: pid)
                AccessibilityNotificationsManager.shared.fetchAutoContext(pid: pid)
            }
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
    private let onWindowChange: ((URL?, String?, pid_t?)) -> Void
    
    init(onWindowChange: @escaping ((URL?, String?, pid_t?)) -> Void) {
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
        
        if doNotTrackXCode {
            onWindowChange((nil, nil, nil))
        } else {
            var title: String? = nil
            var appName: String? = nil
            
            if let window = app.processIdentifier.firstMainWindow {
                title = window.title()
                appName = window.appName()
            } else {
                appName = app.processIdentifier.getAXUIElement().appName()
            }
            
            let windowAppBundleUrl = app.bundleURL
            let windowName = title ?? appName ?? app.localizedName ?? "Unknown"
            
            onWindowChange((windowAppBundleUrl, windowName, app.processIdentifier))
        }
    }
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow window: TrackedWindow
    ) {
        let (windowAppBundleUrl, windowName, pid) = FileRow.getWindowIconAndName(window)
        onWindowChange((windowAppBundleUrl, windowName, pid))
    }
    
    // Tracks when changing focused sub-window in the current window (switching browser tabs, etc.).
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle window: TrackedWindow
    ) {
        let (windowAppBundleUrl, windowName, pid) = FileRow.getWindowIconAndName(window)
        onWindowChange((windowAppBundleUrl, windowName, pid))
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

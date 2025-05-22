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
    
    @State private var currentWindowInfo: (appIconUrl: URL?, name: String?) = (nil, nil)
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
                currentWindowIconUrl: currentWindowInfo.appIconUrl,
                shouldShowAddContextButton: windowName == nil
            )
            
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    if let windowName = windowName {
                        AutoContextButton(
                            text: windowName,
                            isAdd: true,
                            appIconUrl: currentWindowInfo.appIconUrl
                        ) {
                            addWindowToContext()
                        }
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
    static func getWindowIconAndName(_ trackedWindow: TrackedWindow?) -> (URL?, String?) {
        if let trackedWindow = trackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppIconUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName() ?? nil
            
            return (windowAppIconUrl, windowName)
        } else {
            return (nil, nil)
        }
    }
    
    private func initializeCurrentWindowInfo() -> (URL?, String?) {
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
    
    private func addWindowToContext() {
        if let windowName = currentWindowInfo.name {
            windowState.addAutoContextTasks[windowName]?.cancel()
            
            windowState.addAutoContextTasks[windowName] = Task {
                PanelStateCoordinator.shared.fetchWindowContext()
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
    private var currentlyTrackedWindow: TrackedWindow? = nil
    
    private let onWindowChange: ((URL?, String?)) -> Void
    
    init(onWindowChange: @escaping ((URL?, String?)) -> Void) {
        self.onWindowChange = onWindowChange
    }
    
    // Tracks when changing focused window.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow trackedWindow: TrackedWindow
    ) {
        currentlyTrackedWindow = trackedWindow
        let (windowIconAppUrl, windowName) = FileRow.getWindowIconAndName(trackedWindow)
        onWindowChange((windowIconAppUrl, windowName))
    }
    
    // Tracks when changing focused sub-window in the current window.
    // For example, switching browser tabs.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeWindowTitle trackedWindow: TrackedWindow
    ) {
        currentlyTrackedWindow = trackedWindow
        let (windowIconAppUrl, windowName) = FileRow.getWindowIconAndName(trackedWindow)
        onWindowChange((windowIconAppUrl, windowName))
    }
    
    // Cleaning up tracked windows.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didDestroyWindow window: TrackedWindow
    ) {
        let (_, currentlyTrackWindowName) = FileRow.getWindowIconAndName(currentlyTrackedWindow)
        let (_, recentlyTrackedWindowName) = FileRow.getWindowIconAndName(window)
        
        if let currentlyTrackWindowName = currentlyTrackWindowName,
           let recentlyTrackedWindowName = recentlyTrackedWindowName,
           currentlyTrackWindowName == recentlyTrackedWindowName
        {
            currentlyTrackedWindow = nil
            onWindowChange((nil, nil))
        }
    }
    
    // Below is required to conform to AccessibilityNotificationsDelegate protocol but aren't needed in this implementation.
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

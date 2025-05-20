//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct FileRow: View {
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    @State private var currentWindowInfo: (icon: NSImage?, name: String?) = (nil, nil)
    @State private var windowDelegate: WindowChangeDelegate? = nil
    @State private var windowAlreadyInContext: Bool = false
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var contextList: [Context]

    var body: some View {
        HStack(spacing: 6) {
            PaperclipButton(
                currentWindowIcon: currentWindowInfo.icon
            )
            
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    if accessibilityEnabled,
                       !windowAlreadyInContext,
                       let windowName = currentWindowInfo.name
                    {
                        AutoContextButton(
                            icon: currentWindowInfo.icon,
                            text: windowName,
                            action: addWindowToContext,
                            isAdd: true
                        )
                    }
                    
                    if contextList.isEmpty {
                        Spacer()
                    } else {
                        ContextList(contextList: contextList)
                    }
                }
            }
            .scrollIndicators(.hidden)
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
            if let delegate = windowDelegate {
                AccessibilityNotificationsManager.shared.removeDelegate(delegate)
            }
        }
        .onChange(of: currentWindowInfo.name) { _, _ in
            windowAlreadyInContext = detectAlreadyAddedToContext()
        }
        .onChange(of: contextList) { _, _ in
            windowAlreadyInContext = detectAlreadyAddedToContext()
        }
    }
}

// MARK: - Private Functions

extension FileRow {
    static func getWindowIconAndName(_ trackedWindow: TrackedWindow?) -> (NSImage?, String?) {
        if let trackedWindow = trackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowIcon = windowApp.icon
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName() ?? nil
            
            return (windowIcon, windowName)
        } else {
            return (nil, nil)
        }
    }
    
    private func initializeCurrentWindowInfo() -> (NSImage?, String?) {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        return FileRow.getWindowIconAndName(windowsManager.activeTrackedWindow)
    }
    
    private func detectAlreadyAddedToContext() -> Bool {
        if let windowName = currentWindowInfo.name,
            !contextList.isEmpty
        {
            for context in contextList {
                if case .auto(let autoContext) = context {
                    if windowName == autoContext.appName { return true }
                }
            }
            
            return false
        } else {
            return false
        }
    }
    
    private func addWindowToContext() {
        PanelStateCoordinator.shared.fetchWindowContext()
    }
}

// MARK: - Window Change Delegate (to track window changes)

private final class WindowChangeDelegate: AccessibilityNotificationsDelegate {
    private let onWindowChange: ((NSImage?, String?)) -> Void
    
    init(onWindowChange: @escaping ((NSImage?, String?)) -> Void) {
        self.onWindowChange = onWindowChange
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didActivateWindow trackedWindow: TrackedWindow
    ) {
        let (windowIcon, windowName) = FileRow.getWindowIconAndName(trackedWindow)
        onWindowChange((windowIcon, windowName))
    }
    
    // Below is required to conform to AccessibilityNotificationsDelegate protocol but aren't needed in this implementation.
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
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

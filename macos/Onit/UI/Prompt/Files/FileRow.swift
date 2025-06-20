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
    
    var contextList: [Context]

    var body: some View {
        FlowLayout(spacing: 6) {
            PaperclipButton()
            
            addForegroundWindowToContextButton
            pendingWindowContextItems
            addedWindowContextItems
        }
        .onDisappear {
            windowState.cleanUpPendingWindowContextTasks()
        }
    }
}

// MARK: - Child Components

extension FileRow {
    @ViewBuilder
    private var addForegroundWindowToContextButton: some View {
        if accessibilityEnabled,
           autoContextFromCurrentWindow,
           !(windowBeingAddedToContext || windowAlreadyInContext),
           let foregroundWindow = windowState.foregroundWindow
        {
            let foregroundWindowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            let iconBundleURL = WindowHelpers.getWindowAppBundleUrl(window: foregroundWindow.element)
            
            ContextTag(
                text: foregroundWindowName,
                hoverTextColor: .T_2,
                background: .clear,
                hoverBackground: .clear,
                hasHoverBorder: true,
                shouldFadeIn: true,
                iconBundleURL: iconBundleURL,
                tooltip: "Add \(foregroundWindowName) Context"
            ) {
                windowState.addWindowToContext(
                    window: foregroundWindow.element
                )
            }
        }
    }
    
    private var pendingWindowContextItems: some View {
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
    
    @ViewBuilder
    private var addedWindowContextItems: some View {
        if !contextList.isEmpty {
            ForEach(contextList, id: \.self) { context in
                ContextItem(item: context, isEditing: true)
                    .scrollTargetLayout()
                    .contentShape(Rectangle())
            }
        }
    }
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

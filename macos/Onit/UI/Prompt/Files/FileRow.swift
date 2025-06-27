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
    
    var highlightedTextAlreadyInContext: Bool {
        if let highlightedText = windowState.manualAddHighlightedText {
            let pendingContextList = windowState.getPendingContextList()
            
            return TextContextHelpers.checkContextTextAlreadyAdded(
                contextList: pendingContextList,
                text: highlightedText.selectedText
            )
        } else {
            return false
        }
    }
    
    var contextList: [Context]

    var body: some View {
        FlowLayout(spacing: 6) {
            PaperclipButton()
            
            addAutoContextButton
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
    private struct AddAutoContextButton: View {
        var text: String
        var iconBundleURL: URL?
        var iconView: (any View)?
        var tooltip: String
        let action: () -> Void

        var body: some View {
            ContextTag(
                text: text,
                hoverTextColor: .T_2,
                background: .clear,
                hoverBackground: .clear,
                hoverBorderColor: .T_4,
                hasDottedBorder: true,
                shouldFadeIn: true,
                iconBundleURL: iconBundleURL,
                iconView: iconView,
                tooltip: tooltip
            ) {
                action()
            }
        }
    }
    
    @ViewBuilder
    private var addAutoContextButton: some View {
        if accessibilityEnabled && autoContextFromCurrentWindow {
            if let highlightedText = windowState.manualAddHighlightedText,
               !highlightedTextAlreadyInContext
            {
                AddAutoContextButton(
                    text: highlightedText.selectedText,
                    iconView: Image(.text).addIconStyles(iconSize: 14),
                    tooltip: "Add Highlighted Text Content"
                ) {
                    addHighlightedTextToContext(highlightedText)
                }
            } else if !(windowBeingAddedToContext || windowAlreadyInContext),
                      let foregroundWindow = windowState.foregroundWindow
            {
                let window = foregroundWindow.element
                let windowName = WindowHelpers.getWindowName(window: window)
                let iconBundleURL = WindowHelpers.getWindowAppBundleUrl(window: window)
                
                AddAutoContextButton(
                    text: windowName,
                    iconBundleURL: iconBundleURL,
                    tooltip: "Add \(windowName) Context"
                ) {
                    windowState.addWindowToContext(
                        window: foregroundWindow.element
                    )
                }
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

// MARK: - Private Functions

extension FileRow {
    private func addHighlightedTextToContext(_ highlightedText: Input) {
        let pendingContextList = windowState.getPendingContextList()
        
        let textAlreadyAdded = TextContextHelpers.checkContextTextAlreadyAdded(
            contextList: pendingContextList,
            text: highlightedText.selectedText
        )
        
        if !textAlreadyAdded {
            windowState.addContext(texts: [(highlightedText, true)])
        }
    }
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

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
    @ObservedObject private var debugManager = DebugManager.shared
    
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.autoAddHighlightedTextToContext) var autoAddHighlightedTextToContext
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    @Default(.showHighlightedTextInput) var showHighlightedTextInput
    
    @State private var ocrComparisonResult: OCRComparisonResult? = nil
    @State private var showOCRDetails = false

    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var windowBeingAddedToContext: Bool {
        guard let windowState = windowState else { return false }
        
        if let foregroundWindow = windowState.foregroundWindow {
            return windowState.windowContextTasks[foregroundWindow.hash] != nil
        }
        return false
    }
    
    var windowAlreadyInContext: Bool {
        if let foregroundWindow = windowState?.foregroundWindow,
           !contextList.isEmpty
        {
            let windowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            
            for contextItem in contextList {
                if case .auto(let autoContext) = contextItem {
                    if windowName == autoContext.appTitle {
                        return true
                    }
                }
            }
            
            return false
        } else {
            return false
        }
    }
    
    var foregroundWindowContextTagText: String {
        if let foregroundWindow = windowState?.foregroundWindow {
            let foregroundWindowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            if let ocrResult = ocrComparisonResult {
                return "\(ocrResult.matchPercentage)% \(foregroundWindowName)"
            } else {
                return foregroundWindowName
            }
        }
        return ""
    }
    
    var ghostContextTagBackground: Color {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return Color.redDisabled
            } else if ocrResult.matchPercentage < 75 {
                return Color.warningDisabled
            } else {
                return Color.clear
            }
        } else {
            return Color.clear
        }
    }
    
    var ghostContextTagHoverBackground: Color {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return Color.redDisabledHover
            } else if ocrResult.matchPercentage < 75 {
                return Color.warningDisabledHover
            } else {
                return Color.clear
            }
        } else {
            return Color.clear
        }
    }
    
    var contextTagErrorDotColor: Color? {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return Color.red500
            } else if ocrResult.matchPercentage < 75 {
                return Color.orange500
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var showOCRDetailsLink: Bool {
        if let ocrResult = ocrComparisonResult {
            return ocrResult.matchPercentage < 75
        }
        return false
    }

    var contextList: [Context]

    var body: some View {
        VStack(alignment: .leading) {
            FlowLayout(spacing: 6) {
                PaperclipButton()
                
                addWindowToContextButton
                addHighlightedTextToContextButton
                pendingWindowContextItems
                addedWindowContextItems
                highlightedTextContext
            }
            
            ocrDetailsLink
        }
        .sheet(isPresented: $showOCRDetails) {
            if let ocrResult = ocrComparisonResult {
                OCRDetailSheet(result: ocrResult)
            }
        }
        .onAppear() {
            updateOCRComparisonResult()
        }
        .onChange(of: windowState?.foregroundWindow) { _, _ in
            updateOCRComparisonResult()
        }
        .onChange(of: debugManager.ocrComparisonResults) { _, newResults in
            updateOCRComparisonResult(from: newResults)
        }
        .onDisappear {
            windowState?.cleanUpPendingWindowContextTasks()
        }
    }
}

// MARK: - Child Components

extension FileRow {
    private func ghostContextTag(
        text: String,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        tooltip: String,
        action: @escaping () -> Void
    ) -> some View {
        ContextTag(
            text: text,
            hoverTextColor: Color.T_2,
            background: ghostContextTagBackground,
            hoverBackground: ghostContextTagHoverBackground,
            hasHoverBorder: true,
            hasDottedBorder: true,
            shouldFadeIn: true,
            iconBundleURL: iconBundleURL,
            iconView: iconView,
            tooltip: tooltip
        ) {
            action()
        }
    }
    
    @ViewBuilder
    private var addHighlightedTextToContextButton: some View {
        if accessibilityEnabled,
           autoContextFromHighlights,
           let windowState = windowState,
           let trackedPendingInput = windowState.trackedPendingInput
        {
            ghostContextTag(
                text: StringHelpers.removeWhiteSpaceAndNewLines(trackedPendingInput.selectedText),
                iconView: Image(.text).addIconStyles(iconSize: 14),
                tooltip: "Add Highlighted Text To Context"
            ) {
                windowState.pendingInput = trackedPendingInput
                windowState.trackedPendingInput = nil
            }
            .onChange(of: autoAddHighlightedTextToContext) { _, autoAddHighlightedText in
                if autoAddHighlightedText {
                    windowState.pendingInput = trackedPendingInput
                    windowState.trackedPendingInput = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private var addWindowToContextButton: some View {
        if accessibilityEnabled,
           autoContextFromCurrentWindow,
           !(windowBeingAddedToContext || windowAlreadyInContext),
           let windowState = windowState,
           let foregroundWindow = windowState.foregroundWindow
        {
            let foregroundWindowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            let iconBundleURL = WindowHelpers.getWindowAppBundleUrl(window: foregroundWindow.element)
            
            ghostContextTag(
                text: foregroundWindowContextTagText,
                iconBundleURL: iconBundleURL,
                tooltip: "Add \(foregroundWindowName) Context"
            ) {
                windowState.addWindowToContext(window: foregroundWindow.element)
            }
        }
    }
    
    private var pendingWindowContextItems: some View {
        Group {
            if let windowState = windowState {
                ForEach(Array(windowState.windowContextTasks.keys), id: \.self) { uniqueWindowIdentifier in
                    let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.findTrackedWindow(
                        trackedWindowHash: uniqueWindowIdentifier
                    )
                    
                    if let trackedWindow = trackedWindow {
                        ContextTag(
                            text: WindowHelpers.getWindowName(window: trackedWindow.element),
                            background: Color.clear,
                            hoverBackground: Color.clear,
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
    }
    
    @ViewBuilder
    private var highlightedTextContext: some View {
        if let pendingInput = windowState?.pendingInput {
            ContextTag(
                text: StringHelpers.removeWhiteSpaceAndNewLines(pendingInput.selectedText),
                borderColor: showHighlightedTextInput ? Color.S_4 : Color.clear,
                iconView: Image(.text).addIconStyles(iconSize: 14)
            ) {
                showHighlightedTextInput = true
            } removeAction: {
                windowState?.pendingInput = nil
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

    @ViewBuilder
    private var ocrDetailsLink: some View {
        // OCR Details Link
        if showOCRDetailsLink {
            HStack {
                Button("Details →") {
                    showOCRDetails = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(contextTagErrorDotColor)
                Spacer()
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - OCR Comparison Helpers

extension FileRow {
    private func updateOCRComparisonResult() {
        updateOCRComparisonResult(from: debugManager.ocrComparisonResults)
    }
    
    private func updateOCRComparisonResult(from results: [OCRComparisonResult]) {
        guard let foregroundWindow = windowState?.foregroundWindow else {
            ocrComparisonResult = nil
            return
        }
        let foregroundWindowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
        
        // Find the most recent OCR result that matches our current window
        let result = results
            .filter { result in
                // Match by app title and check if it's recent (within last 5 minutes)
                result.appTitle == foregroundWindowName &&
                Date().timeIntervalSince(result.timestamp) < 300
            }
            .sorted { $0.timestamp > $1.timestamp }
            .first
        ocrComparisonResult = result
    }
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif

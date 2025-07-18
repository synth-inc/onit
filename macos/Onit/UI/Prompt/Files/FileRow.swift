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
    
    var contextTagText: String {
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
    
    var contextTagBackground: Color {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return .redDisabled
            } else if ocrResult.matchPercentage < 75 {
                return .warningDisabled
            } else {
                return .clear
            }
        } else {
            return .clear
        }
    }
    
    var contextTagHoverBackground: Color {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return .redDisabledHover
            } else if ocrResult.matchPercentage < 75 {
                return .warningDisabledHover
            } else {
                return .clear
            }
        } else {
            return .clear
        }
    }
    
    var contextTagErrorDotColor: Color? {
        if let ocrResult = ocrComparisonResult {
            if ocrResult.matchPercentage < 50 {
                return .red
            } else if ocrResult.matchPercentage < 75 {
                return .yellow
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
                unpinnedHighlightedTextContextItem
                pinnedHighlightedTextContextItems
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
        .onChange(of: autoAddHighlightedTextToContext) { _, autoAddHighlightedText in
            if autoAddHighlightedText {
                morphHighlightedTextGhostTagToContextTag()
            } else {
                morphHighlightedTextUnpinnedContextTagToGhostTag()
            }
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
            textColor: .T_2,
            hoverTextColor: .white,
            background: contextTagBackground,
            hoverBackground: contextTagHoverBackground,
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
           let trackedPendingInput = windowState.trackedPendingInput,
           !windowState.pinnedPendingInputs.contains(trackedPendingInput)
        {
            ghostContextTag(
                text: StringHelpers.removeWhiteSpaceAndNewLines(trackedPendingInput.selectedText),
                iconView: Image(.text).addIconStyles(iconSize: 14),
                tooltip: "Add Highlighted Text To Context"
            ) {
                addTrackedGhostHighlightedTextToContext(trackedPendingInput)
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
                text: contextTagText,
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
    }
    
    @ViewBuilder
    private var unpinnedHighlightedTextContextItem: some View {
        if let windowState = windowState,
           let unpinnedPendingInput = windowState.unpinnedPendingInput,
           !windowState.pinnedPendingInputs.contains(unpinnedPendingInput)
        {
            ContextTag(
                text: StringHelpers.removeWhiteSpaceAndNewLines(unpinnedPendingInput.selectedText),
                borderColor: unpinnedPendingInput == windowState.selectedPendingInput ? .gray400 : .clear,
                iconView: Image(.text).addIconStyles(iconSize: 14)
            ) {
                showHighlightedText(input: unpinnedPendingInput)
            } pinAction: {
                pinUnpinnedHighlightedText(unpinnedPendingInput)
            } removeAction: {
                removeHighlightedText()
            }
        }
    }
    
    @ViewBuilder
    private var pinnedHighlightedTextContextItems: some View {
        if let windowState = windowState {
            ForEach(windowState.pinnedPendingInputs, id: \.self) { pinnedPendingInput in
                ContextTag(
                    text: pinnedPendingInput.selectedText,
                    borderColor: pinnedPendingInput == windowState.selectedPendingInput ? .gray400 : .clear,
                    iconView: Image(.text).addIconStyles(iconSize: 14),
                    iconViewCornerIcon: .pin
                ) {
                    showHighlightedText(input: pinnedPendingInput)
                } removeAction: {
                    removeHighlightedText(pinnedPendingInput)
                }
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

// MARK: - Private Functions

extension FileRow {
    private func morphHighlightedTextGhostTagToContextTag() {
        guard let windowState = windowState else { return }

        windowState.selectedPendingInput = windowState.trackedPendingInput
        windowState.unpinnedPendingInput = windowState.trackedPendingInput
        windowState.trackedPendingInput = nil
    }

    private func morphHighlightedTextUnpinnedContextTagToGhostTag() {
        guard let windowState = windowState else { return }

        windowState.trackedPendingInput = windowState.unpinnedPendingInput
        windowState.selectedPendingInput = nil
        windowState.unpinnedPendingInput = nil
    }

    private func pinHighlightedText(_ windowState: OnitPanelState, _ input: Input) {
        if !windowState.pinnedPendingInputs.contains(input) {
            windowState.pinnedPendingInputs.append(input)
        }
    }

    private func addTrackedGhostHighlightedTextToContext(_ trackedPendingInput: Input) {
        guard let windowState = windowState else { return }

        pinHighlightedText(windowState, trackedPendingInput)

        windowState.selectedPendingInput = trackedPendingInput
        windowState.trackedPendingInput = nil
    }

    private func pinUnpinnedHighlightedText(_ unpinnedPendingInput: Input) {
        guard let windowState = windowState else { return }

        pinHighlightedText(windowState, unpinnedPendingInput)

        windowState.unpinnedPendingInput = nil
    }

    private func showHighlightedText(input: Input) {
        guard let windowState = windowState else { return }

        windowState.selectedPendingInput = input
        Defaults[.showHighlightedTextInput] = true
    }

    private func removeUnpinnedHighlightedTextItem(_ windowState: OnitPanelState) {
        let showingUnpinnedHighlightedText = windowState.selectedPendingInput == windowState.unpinnedPendingInput

        /// Removing `InputView` from the UI if it matches the removed unpinned highlighted text.
        if showingUnpinnedHighlightedText {
            windowState.selectedPendingInput = nil
        }

        windowState.unpinnedPendingInput = nil
    }
    private func removePinnedHighlightedTextItem(_ windowState: OnitPanelState, _ pinnedPendingInput: Input) {
        let showingPinnedHighlightedText = windowState.selectedPendingInput == pinnedPendingInput

        /// Removing `InputView` from the UI if it matches the removed pinned highlighted text.
        if showingPinnedHighlightedText {
            windowState.selectedPendingInput = nil
        }

        windowState.pinnedPendingInputs.removeAll { $0 == pinnedPendingInput }
    }
    private func removeHighlightedText(_ pinnedPendingInput: Input? = nil) {
        guard let windowState = windowState else { return }

        if let pinnedPendingInput = pinnedPendingInput {
            removePinnedHighlightedTextItem(windowState, pinnedPendingInput)
        } else {
            removeUnpinnedHighlightedTextItem(windowState)
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

//
//  QuickEditView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import SwiftUI
import Defaults

struct QuickEditView: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) private var windowState
    @FocusState private var isFocused: Bool
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var textHeight: CGFloat = 44
    @State private var displayedPrompt: Prompt?
    
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var quickEditManager = QuickEditManager.shared
    
    @State private var currentWindowInfo: (
        appBundleUrl: URL?,
        name: String?,
        pid: pid_t?
    ) = (nil, nil, nil)
    
    @State private var isAddingContext: Bool = false
    
    private let maxTextHeight: CGFloat = 100
    
    private var showingAlert: Bool {
        showTwoWeekProTrialEndedAlert || appState.showFreeLimitAlert || appState.showProLimitAlert
    }
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var shouldShowWindowContext: Bool {
        return autoContextFromCurrentWindow && 
               accessibilityEnabled && 
               currentWindowInfo.name != nil &&
               (isWindowAlreadyInContext || isAddingContext)
    }
    
    var isWindowAlreadyInContext: Bool {
        guard let windowState = windowState else { return false }
        guard let windowName = currentWindowInfo.name else {
            return false
        }
        
        return windowState.pendingContextList.contains { context in
            if case .auto(let autoContext) = context {
                return windowName == autoContext.appTitle
            }
            return false
        }
    }
    
    var body: some View {
        mainContent
            .background(VibrantVisualEffectView { Color.quickEditBG })
            .addBorder(cornerRadius: 14, lineWidth: 1, stroke: .T_4)
            .frame(minWidth: 360, minHeight: 120, maxHeight: 605)
            .onAppear(perform: handleOnAppear)
            .modifier(GeneratingPromptModifier(
                windowState: windowState,
                displayedPrompt: $displayedPrompt
            ))
            .modifier(CurrentChatModifier(
                windowState: windowState,
                displayedPrompt: $displayedPrompt
            ))
            .modifier(PendingContextModifier(
                windowState: windowState,
                currentWindowInfo: currentWindowInfo,
                isAddingContext: $isAddingContext
            ))
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 8) {
            headerView
            
            responseSection
            
            if let windowState = windowState {
                textfield(windowState: windowState)
            }
            
            footerSection
        }
    }
    
    @ViewBuilder
    private var responseSection: some View {
        if let prompt = displayedPrompt {
            QuickEditResponseView(
                prompt: prompt,
                isEditableElement: quickEditManager.isEditableElement
            )
            
            Color.gray500
                .frame(height: 1)
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        PromptCoreFooter(
            audioRecorder: audioRecorder,
            disableSend: isDisabledSend,
            handleSend: handleSend
        )
    }
    
    // MARK: - Computed Properties
    
    private var isDisabledSend: Bool {
        guard let windowState = windowState else { return true }
        return windowState.pendingInstruction.isEmpty
    }
    
    // MARK: - Event Handlers
    
    private func handleOnAppear() {
        loadCurrentWindowInfo()
        
        if autoContextFromCurrentWindow && accessibilityEnabled {
            addCurrentWindowToContext()
        }
    }
}

// MARK: - Components

extension QuickEditView {
    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            if shouldShowWindowContext,
               let appBundleUrl = currentWindowInfo.appBundleUrl,
               let windowName = currentWindowInfo.name {
                ContextTag(
                    text: windowName,
                    textColor: .T_2,
                    hoverTextColor: .T_2,
                    background: .clear,
                    hoverBackground: .T_8,
                    maxWidth: 250,
                    isLoading: isAddingContext,
                    iconBundleURL: isAddingContext ? nil : appBundleUrl,
                    iconView: isAddingContext ? LoaderPulse() : nil,
                    tooltip: windowName,
                    action: isAddingContext ? nil : { showContextWindow(windowName: windowName) },
                    removeAction: isAddingContext ? nil : { removeCurrentWindowFromContext() }
                )
                .buttonStyle(PlainButtonStyle())
            } else {
                IconButton(
                    icon: .addContext,
                    iconSize: 18,
                    tooltipPrompt: "Add window context"
                ) {
                    addCurrentWindowToContext()
                }
            }
            
            Spacer()
            
            IconButton(
                icon: .layoutRight,
                iconSize: 16,
                tooltipPrompt: "Open Onit"
            ) {
                PanelStateCoordinator.shared.launchPanel(for: windowState, createNewChat: false)
                QuickEditManager.shared.hide()
            }
        }
        .frame(height: 24, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    private func textfield(windowState: OnitPanelState) -> some View {
        @Bindable var bindableWindowState = windowState
        
        return TextViewWrapper(
            text: $bindableWindowState.pendingInstruction,
            cursorPosition: $bindableWindowState.pendingInstructionCursorPosition,
            dynamicHeight: $textHeight,
            onSubmit: handleSend,
            maxHeight: maxTextHeight,
            placeholder: "New instructions / for actions",
            audioRecorder: audioRecorder,
            isDisabled: showingAlert,
            detectLinks: true
        )
        .frame(height: min(textHeight, maxTextHeight))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .appFont(.medium16)
        .foregroundStyle(.white)
        .focused($isFocused)
        .onAppear { 
            isFocused = true
        }
        .onChange(of: showingAlert) { _, new in
            isFocused = !new
        }
        .disabled(showingAlert)
        .allowsHitTesting(!showingAlert)
    }
}

// MARK: - Private Functions

extension QuickEditView {
    
    private func handleSend() {
        guard let windowState = windowState,
              !windowState.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await appState.checkSubscriptionAlerts {
                windowState.sendAction(accountId: appState.account?.id)
            }
        }
    }
    
    // MARK: Window Context
    
    private func loadCurrentWindowInfo() {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        
        if let windowState = windowState,
           let trackedWindow = windowState.foregroundWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppBundleUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName()
            
            currentWindowInfo = (windowAppBundleUrl, windowName, pid)
        }
    }
    
    private func addCurrentWindowToContext() {
        guard let windowState = windowState,
              let pid = currentWindowInfo.pid,
              let focusedWindow = pid.firstMainWindow,
              !isAddingContext,
              !isWindowAlreadyInContext else {
            return
        }
        
        isAddingContext = true
        
        if let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.trackWindowForElement(focusedWindow, pid: pid) {
            windowState.addWindowToContext(window: trackedWindow.element)
        }
    }
    
    private func removeCurrentWindowFromContext() {
        guard let windowState = windowState,
              let windowName = currentWindowInfo.name else {
            return
        }
        
        windowState.pendingContextList.removeAll { context in
            if case .auto(let autoContext) = context {
                return windowName == autoContext.appTitle
            }
            return false
        }
    }
    
    private func showContextWindow(windowName: String) {
        guard let windowState = windowState,
              let context = windowState.pendingContextList.first(where: { context in
            if case .auto(let autoContext) = context {
                return windowName == autoContext.appTitle
            }
            return false
        }) else {
            return
        }
        
        ContextWindowsManager.shared.showContextWindow(
            windowState: windowState,
            context: context
        )
    }
}

// MARK: - Custom Modifiers

struct GeneratingPromptModifier: ViewModifier {
    let windowState: OnitPanelState?
    @Binding var displayedPrompt: Prompt?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: windowState?.generatingPrompt) { _, generatingPrompt in
                if let generatingPrompt = generatingPrompt {
                    displayedPrompt = generatingPrompt
                }
            }
    }
}

struct CurrentChatModifier: ViewModifier {
    let windowState: OnitPanelState?
    @Binding var displayedPrompt: Prompt?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: windowState?.currentChat) { _, currentChat in
                if displayedPrompt == nil, let lastPrompt = currentChat?.prompts.last {
                    displayedPrompt = lastPrompt
                }
            }
    }
}

struct PendingContextModifier: ViewModifier {
    let windowState: OnitPanelState?
    let currentWindowInfo: (appBundleUrl: URL?, name: String?, pid: pid_t?)
    @Binding var isAddingContext: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: windowState!.pendingContextList) { _, newContextList in
                handleContextListChange(newContextList)
            }
    }
    
    private func handleContextListChange(_ newContextList: [Context]) {
        guard isAddingContext,
              let windowName = currentWindowInfo.name else {
            return
        }
        
        let containsWindow = newContextList.contains { context in
            if case .auto(let autoContext) = context {
                return windowName == autoContext.appTitle
            }
            return false
        }
        
        if containsWindow {
            isAddingContext = false
        }
    }
}

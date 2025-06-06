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
        VStack(spacing: 8) {
            headerView
            
            if let prompt = displayedPrompt {
                QuickEditResponseView(
                    prompt: prompt,
                    isEditableElement: quickEditManager.isEditableElement
                )
                
                Color.gray500
                    .frame(height: 1)
            }
    
            textfield
            
            PromptCoreFooter(
                audioRecorder: audioRecorder,
                disabledSend: windowState.pendingInstruction.isEmpty,
                handleSend: handleSend
            )
        }
        .background(VibrantVisualEffectView { Color.quickEditBG })
        .addBorder(cornerRadius: 14, lineWidth: 1, stroke: .T_4)
        .frame(minWidth: 360, minHeight: 120, maxHeight: 605)
        .onChange(of: windowState.generatingPrompt) { _, generatingPrompt in
            if let generatingPrompt = generatingPrompt {
                displayedPrompt = generatingPrompt
            }
        }
        .onChange(of: windowState.currentChat) { _, currentChat in
            if displayedPrompt == nil, let lastPrompt = currentChat?.prompts.last {
                displayedPrompt = lastPrompt
            }
        }
        .onAppear {
            loadCurrentWindowInfo()
            
            if autoContextFromCurrentWindow && accessibilityEnabled {
                addCurrentWindowToContext()
            }
        }
        .onChange(of: windowState.pendingContextList) { _, newContextList in
            if isAddingContext,
               let windowName = currentWindowInfo.name,
               newContextList.contains(where: { context in
                   if case .auto(let autoContext) = context {
                       return windowName == autoContext.appTitle
                   }
                   return false
               }) {
                isAddingContext = false
            }
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
                    action: {
                        addCurrentWindowToContext()
                    },
                    tooltipPrompt: "Add window context"
                )
            }
            
            Spacer()
            
            IconButton(
                icon: .layoutRight,
                iconSize: 16,
                action: {
                    PanelStateCoordinator.shared.launchPanel(for: windowState, createNewChat: false)
                    QuickEditManager.shared.hide()
                },
                tooltipPrompt: "Open Onit"
            )
        }
        .frame(height: 24, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    private var textfield: some View {
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
        guard !windowState.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await appState.checkSubscriptionAlerts {
                windowState.sendAction(accountId: appState.account?.id)
            }
        }
    }
    
    // MARK: Window Context
    
    private func loadCurrentWindowInfo() {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        
        if let trackedWindow = windowsManager.activeTrackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppBundleUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName()
            
            currentWindowInfo = (windowAppBundleUrl, windowName, pid)
        }
    }
    
    private func addCurrentWindowToContext() {
        guard let pid = currentWindowInfo.pid,
              let focusedWindow = pid.firstMainWindow,
              !isAddingContext,
              !isWindowAlreadyInContext else {
            return
        }
        
        isAddingContext = true
        
        let _ = AccessibilityNotificationsManager.shared.windowsManager.append(focusedWindow, pid: pid)
        AccessibilityNotificationsManager.shared.fetchAutoContext(pid: pid, state: windowState)
    }
    
    private func removeCurrentWindowFromContext() {
        guard let windowName = currentWindowInfo.name else {
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
        guard let context = windowState.pendingContextList.first(where: { context in
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

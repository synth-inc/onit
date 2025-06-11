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
    
    private let maxWidth: CGFloat = 365
    private let maxTextHeight: CGFloat = 100
    
    private var showingAlert: Bool {
        showTwoWeekProTrialEndedAlert || appState.showFreeLimitAlert || appState.showProLimitAlert
    }
    
    var body: some View {
        VStack(spacing: 8) {
            headerView
            
            if let prompt = displayedPrompt {
                QuickEditResponseView(prompt: prompt)
                
                Color.gray500
                    .frame(height: 1)
            }
    
            textfield
            
            PromptCoreFooter(
                audioRecorder: audioRecorder,
                sendDisabled: windowState.pendingInstruction.isEmpty,
                handleSend: handleSend
            )
        }
        .background(VibrantVisualEffectView { Color.quickEditBG })
        .addBorder(cornerRadius: 14, lineWidth: 1, stroke: .T_4)
        .frame(minWidth: 320, maxWidth: maxWidth, minHeight: 120, maxHeight: 605)
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
    }
}

// MARK: - Components

extension QuickEditView {
    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            IconButton(
                icon: .addContext,
                iconSize: 18,
                action: {
                    // TODO: KNA - Quick Edit
                },
                tooltipPrompt: "Add window context"
            )
            
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
}

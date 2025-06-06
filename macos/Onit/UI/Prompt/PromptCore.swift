//
//  PromptCore.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import Defaults
import KeyboardShortcuts
import SwiftData
import SwiftUI

struct PromptCore: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) private var windowState
    @Query(sort: \Chat.timestamp, order: .reverse) private var allChats: [Chat]
    
    @Default(.mode) var mode
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    
    private var chats: [Chat] {
        let chatsFilteredByAccount = allChats
            .filter { $0.accountId == appState.account?.id }
        
        return PanelStateCoordinator.shared.filterPanelChats(chatsFilteredByAccount)
    }
    
    let isEditing: Bool
    let editingText: Binding<String>?
    
    init(
        isEditing: Bool = false,
        editingText: Binding<String>? = nil
    ) {
        self.isEditing = isEditing
        self.editingText = editingText
    }
    
    @StateObject private var audioRecorder = AudioRecorder()
    
    @State private var notificationDelegate: NotificationDelegate? = nil
    
    @State private var textHeight: CGFloat = 20
    private let maxHeightLimit: CGFloat = 100
    
    @FocusState private var isFocused: Bool
    
    private var unfocusedBorder = GradientBorder(
        colorOne: .gray500,
        colorTwo: .gray500
    )
    
    private var remoteBorder = GradientBorder(
        colorOne: Color(hex: "#6D6AFD") ?? .gray800,
        colorTwo: Color(hex: "#B3ADDA") ?? .gray800
    )
    
    private var localBorder = GradientBorder(
        colorOne: Color(hex: "#7ECD8C") ?? .gray800,
        colorTwo: Color(hex: "#4AA4BF") ?? .gray800
    )
    
    private var shouldIndicateDisabled: Bool {
        !windowState.websiteUrlsScrapeQueue.isEmpty || !windowState.addAutoContextTasks.isEmpty
    }
    
    private var showingAlert: Bool {
        showTwoWeekProTrialEndedAlert || appState.showFreeLimitAlert || appState.showProLimitAlert
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let pendingInput = windowState.pendingInput {
                InputView(input: pendingInput)
            }
            
            VStack(spacing: 6) {
                contextAndInput
                PromptCoreFooter(
                    audioRecorder: audioRecorder,
                    handleSend: handleSend
                )
            }
        }
        .background {
            if !isEditing {
                if !windowState.isTyping {
                    upListener
                    downListener
                }
                
                newListener
            }
        }
        .onAppear {
            let delegate = NotificationDelegate(
                onPanelBecomeKey: {
                    if !showingAlert {
                        isFocused = true
                    }
                },
                onPanelResignKey: {
                    isFocused = false
                }
            )
            
            notificationDelegate = delegate
            windowState.addDelegate(delegate)
        }
        .onDisappear {
            if let delegate = notificationDelegate {
                windowState.removeDelegate(delegate)
            }
        }
        .onChange(of: editingText?.wrappedValue ?? windowState.pendingInstruction) { _, _ in
            windowState.detectIsTyping()
        }
        .onChange(of: windowState.pendingInstructionCursorPosition) {
            if !isEditing {
                windowState.detectIsTyping()
            }
        }
    }
}

// MARK: - Child Components

extension PromptCore {
    @ViewBuilder
    private var textField: some View {
        @Bindable var windowState = windowState
        
        TextViewWrapper(
            text: editingText ?? $windowState.pendingInstruction,
            cursorPosition: $windowState.pendingInstructionCursorPosition,
            dynamicHeight: $textHeight,
            onSubmit: handleSend,
            maxHeight: maxHeightLimit,
            placeholder: placeholderText,
            audioRecorder: audioRecorder,
            isDisabled: showingAlert,
            detectLinks: true
        )
        .frame(height: min(textHeight, maxHeightLimit))
        .appFont(.medium16)
        .foregroundStyle(.white)
        .opacity(shouldIndicateDisabled ? 0.5 : 1)
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onChange(of: windowState.textFocusTrigger) { _, _ in
            isFocused = true
        }
        .onChange(of: showingAlert) { _, new in
            isFocused = !new
        }
        .disabled(showingAlert)
        .allowsHitTesting(!showingAlert)
    }
    
    private var contextAndInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !appState.subscriptionPlanError.isEmpty {
                Text(appState.subscriptionPlanError)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: .red
                    )
            }
            
            FileRow(contextList: windowState.pendingContextList)
            textField
        }
        .padding(12)
        .background(.gray800)
        .addGradientBorder(
            cornerRadius: 8,
            lineWidth: 1.6,
            gradientBorder:
                !isFocused ? unfocusedBorder :
                isRemote ? remoteBorder :
                localBorder
        )
        .addAnimation(dependency: isRemote, duration: 0.3)
        .addAnimation(dependency: isFocused, duration: 0.3)
        .padding(.top, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Keyboard Arrow Key Listeners

extension PromptCore {
    var upListener: some View {
        Button {
            guard !chats.isEmpty else { return }

            if windowState.historyIndex + 1 < chats.count {
                windowState.historyIndex += 1
                windowState.currentChat = chats[windowState.historyIndex]
                windowState.currentPrompts = chats[windowState.historyIndex].prompts
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if windowState.historyIndex > 0 {
                windowState.historyIndex -= 1
                windowState.currentChat = chats[windowState.historyIndex]
                windowState.currentPrompts = chats[windowState.historyIndex].prompts
            } else if windowState.historyIndex == 0 {
                windowState.historyIndex = -1
                windowState.currentChat = nil
                windowState.currentPrompts = nil
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
    }
    
    var newListener: some View {
        Button {
            windowState.newChat()
        } label: {
            EmptyView()
        }
        .keyboardShortcut("n")
    }
}

// MARK: - Private Variables

extension PromptCore {
    private var isRemote: Bool {
        switch mode {
        case .remote: return true
        default: return false
        }
    }
    
    private var placeholderText: String {
        if let currentChat = windowState.currentChat {
            if !currentChat.isEmpty {

                if let keyboardShortcutString = KeyboardShortcuts.getShortcut(for: .newChat)?
                    .description
                {
                    "Follow-up... (" + keyboardShortcutString + " for new)"
                } else {
                    "Follow-up..."
                }

            } else {
                "New instructions..."
            }
        } else {
            "New instructions..."
        }
    }
}

// MARK: - Private Functions

extension PromptCore {
    private func handleSend() {
        Task {
            await appState.checkSubscriptionAlerts {
                windowState.sendAction(accountId: appState.account?.id)
            }
        }
    }
}

// MARK: - Notification Delegate

private final class NotificationDelegate: OnitPanelStateDelegate {
    let onPanelBecomeKey: () -> Void
    let onPanelResignKey: () -> Void
    
    init(
        onPanelBecomeKey: @escaping () -> Void,
        onPanelResignKey: @escaping () -> Void
    ) {
        self.onPanelBecomeKey = onPanelBecomeKey
        self.onPanelResignKey = onPanelResignKey
    }
    
    func panelBecomeKey(state: OnitPanelState) {
        onPanelBecomeKey()
    }
    
    func panelResignKey(state: OnitPanelState) {
        onPanelResignKey()
    }
    
    // These are required to conform to the OnitPanelStateDelegate protocol, but they aren't needed in this implementation.
    func panelStateDidChange(state: OnitPanelState) {}
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}

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
    @Default(.showHighlightedTextInput) var showHighlightedTextInput
    
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
    
    @State private var showSlashMenu: Bool = false
    
    @State private var disableSend: Bool = false
    
    @FocusState private var isFocused: Bool
    
    private var unfocusedBorder = GradientBorder(
        colorOne: Color.S_5,
        colorTwo: Color.S_5
    )
    
    private var remoteBorder = GradientBorder(
        colorOne: Color(hex: "#6D6AFD") ?? Color.S_5,
        colorTwo: Color(hex: "#B3ADDA") ?? Color.S_5
    )
    
    private var localBorder = GradientBorder(
        colorOne: Color(hex: "#7ECD8C") ?? Color.S_5,
        colorTwo: Color(hex: "#4AA4BF") ?? Color.S_5
    )
    
    private var text: String {
        editingText?.wrappedValue ?? windowState?.pendingInstruction ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                contextAndInput
                PromptCoreFooter(
                    audioRecorder: audioRecorder,
                    disableSend: disableSend,
                    handleSend: handleSend
                )
            }
        }
        .background {
            if !isEditing, let windowState = windowState {
                if !showSlashMenu && (windowState.showContextMenu != true) && (windowState.isTyping != true) {
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
            
            if text.isEmpty { disableSend = true }
            
            notificationDelegate = delegate
            windowState?.addDelegate(delegate)
        }
        .onDisappear {
            if let delegate = notificationDelegate {
                windowState?.removeDelegate(delegate)
            }
        }
        .onChange(of: text) { old, new in
            let slashMenuOpened = new == "/" && old != "/ "
            showSlashMenu = slashMenuOpened
            windowState?.showContextMenu = slashMenuOpened // This should be removed later when the Slash Menu is developed.
            disableSend = slashMenuOpened || new.isEmpty
            
            windowState?.detectIsTyping()
        }
        .onChange(of: windowState?.pendingInstructionCursorPosition) {
            if !isEditing {
                windowState?.detectIsTyping()
            }
        }
    }
}

// MARK: - Child Components

extension PromptCore {
    @ViewBuilder
    private var textField: some View {
        if let windowState = windowState {
            @Bindable var bindableWindowState = windowState
            
            TextViewWrapper(
                text: editingText ?? $bindableWindowState.pendingInstruction,
                cursorPosition: $bindableWindowState.pendingInstructionCursorPosition,
                dynamicHeight: $textHeight,
                onSubmit: handleSend,
                maxHeight: maxHeightLimit,
                placeholder: placeholderText,
                audioRecorder: audioRecorder,
                isDisabled: showingAlert,
                detectLinks: true
            )
            .frame(height: min(textHeight, maxHeightLimit))
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
            // TODO: LOYD - This should be commented in when the Slash Menu is built.
//          .popover(
//              isPresented: $showSlashMenu
//          ) {
//              SlashMenu()
//          }
        } else {
            EmptyView()
        }
    }
    
    private var contextAndInput: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showHighlightedTextInput, let windowState = windowState, let pendingInput = windowState.pendingInput {
                InputView(input: pendingInput, inputExpanded: true)
            }
            
            if !appState.subscriptionPlanError.isEmpty {
                Text(appState.subscriptionPlanError)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: .red
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                FileRow(contextList: windowState?.pendingContextList ?? [])
                textField
            }
            .padding(.top, 6)
            .padding([.horizontal, .bottom], 12)
        }
        .padding(.top, 2)
        .padding([.horizontal, .bottom], 0)
        .background(Color.messageBG)
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
    private var upListener: some View {
        KeyListener(key: .upArrow, modifiers: []) {
            guard !chats.isEmpty, let windowState = windowState else { return }

            if windowState.historyIndex + 1 < chats.count {
                windowState.historyIndex += 1
                windowState.currentChat = chats[windowState.historyIndex]
                windowState.currentPrompts = chats[windowState.historyIndex].prompts
            }
        }
    }

    private var downListener: some View {
        KeyListener(key: .downArrow, modifiers: []) {
            guard let windowState = windowState else { return }
            
            if windowState.historyIndex > 0 {
                windowState.historyIndex -= 1
                windowState.currentChat = chats[windowState.historyIndex]
                windowState.currentPrompts = chats[windowState.historyIndex].prompts
            } else if windowState.historyIndex == 0 {
                windowState.historyIndex = -1
                windowState.currentChat = nil
                windowState.currentPrompts = nil
            }
        }
    }
    
    private var newListener: some View {
        KeyListener(key: "n") {
            windowState?.newChat()
        }
    }
}

// MARK: - Private Variables

extension PromptCore {
    private var shouldIndicateDisabled: Bool {
        guard let windowState = windowState else { return true }
        return !windowState.websiteUrlsScrapeQueue.isEmpty || !windowState.windowContextTasks.isEmpty
    }
    
    private var showingAlert: Bool {
        showTwoWeekProTrialEndedAlert || appState.showFreeLimitAlert || appState.showProLimitAlert
    }
    
    private var isRemote: Bool {
        switch mode {
        case .remote: return true
        default: return false
        }
    }
    
    private var placeholderText: String {
        guard let windowState = windowState else {
            return ""
        }
        
        if let currentChat = windowState.currentChat {
            if !currentChat.isEmpty {

                if let keyboardShortcutString = KeyboardShortcuts.getShortcut(for: .newChat)?
                    .description
                {
                    return "Follow-up... (" + keyboardShortcutString + " for new), / for actions"
                } else {
                    return "Follow-up..., / for actions"
                }

            } else {
                return "New instructions, / for actions"
            }
        } else {
            return "New instructions, / for actions"
        }
    }
}

// MARK: - Private Functions

extension PromptCore {
    private func handleSend() {
        Task {
            await appState.checkSubscriptionAlerts {
                windowState?.sendAction(accountId: appState.account?.id)
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

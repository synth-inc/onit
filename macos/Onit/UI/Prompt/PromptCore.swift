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
    @Environment(\.windowState) private var windowState
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @Default(.mode) var mode
    
    private let placeholder: String?
    private let text: Binding<String>?
    private let onSubmit: (() -> Void)?
    private let onUnfocus: (() -> Void)?

    private let cursorPosition: Binding<Int>?
    private let detectLinks: Bool
    private let isEditing: Bool

    private let padding: CGFloat
    
    init(
        placeholder: String? = nil,
        text: Binding<String>? = nil,
        onSubmit: (() -> Void)? = nil,
        onUnfocus: (() -> Void)? = nil,
        
        cursorPosition: Binding<Int>? = nil,
        detectLinks: Bool = true,
        isEditing: Bool = false,
        
        padding: CGFloat = 12
    ) {
        self.placeholder = placeholder
        self.text = text
        self.onSubmit = onSubmit
        self.onUnfocus = onUnfocus
        
        self.cursorPosition = cursorPosition
        self.detectLinks = detectLinks
        self.isEditing = isEditing
        
        self.padding = padding
    }
    
    @StateObject private var audioRecorder = AudioRecorder()
    
    @State private var isPressedModelSelectionButton: Bool = false
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
    
    private var sendDisabled: Bool {
        if let text = text {
            return text.wrappedValue.isEmpty
        } else {
            return windowState.pendingInstruction.isEmpty
        }
    }
    
    var textBinding: Binding<String> {
        if let text = text {
            return text
        } else {
            return Binding(
                get: { windowState.pendingInstruction },
                set: { windowState.pendingInstruction = $0 }
            )
        }
    }
    
    var cursorPositionBinding: Binding<Int> {
        if let cursorPosition = cursorPosition {
            return cursorPosition
        } else {
            return Binding(
                get: { windowState.pendingInstructionCursorPosition },
                set: { windowState.pendingInstructionCursorPosition = $0 }
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let pendingInput = windowState.pendingInput {
                InputView(input: pendingInput)
            }
            
            VStack(spacing: 6) {
                VStack(spacing: 8) {
                    FileRow(contextList: windowState.pendingContextList)
                    
                    textField(
                        text: textBinding,
                        cursorPosition: cursorPositionBinding
                    )
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
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
                .padding(.top, padding)
                .padding(.horizontal, padding)
                
                PromptCoreFooter(
                    isPressedModelSelectionButton: $isPressedModelSelectionButton,
                    promptText: textBinding,
                    cursorPosition: cursorPositionBinding,
                    audioRecorder: audioRecorder,
                    sendDisabled: sendDisabled,
                    sendAction: {
                        if !sendDisabled {
                            if let onSubmit = onSubmit { onSubmit() }
                            else { windowState.sendAction() }
                        }
                    },
                    isEditing: isEditing
                )
            }
        }
        .background {
            if !isEditing {
                upListener
                downListener
                newListener
            }
        }
    }
}

// MARK: - Child Components

extension PromptCore {
    @ViewBuilder
    private func textField(
        text: Binding<String>,
        cursorPosition: Binding<Int>
    ) -> some View {
        TextViewWrapper(
            text: text,
            cursorPosition: cursorPosition,
            dynamicHeight: $textHeight,
            onSubmit: onSubmit ?? windowState.sendAction,
            maxHeight: maxHeightLimit,
            placeholder: placeholder ?? placeholderTextFallback,
            audioRecorder: audioRecorder,
            detectLinks: detectLinks
        )
        .frame(height: min(textHeight, maxHeightLimit))
        .appFont(.medium16)
        .foregroundStyle(.white)
        .opacity(windowState.websiteUrlsScrapeQueue.isEmpty ? 1 : 0.5)
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onChange(of: windowState.textFocusTrigger) { isFocused = true }
        .onChange(of: isFocused) {
            if let onUnfocus = onUnfocus,
                !isFocused && !isPressedModelSelectionButton
            {
                onUnfocus()
            }
        }
        // .padding(12)
        // .background(.gray800)
        // .addGradientBorder(
        //     cornerRadius: 8,
        //     lineWidth: 1.6,
        //     gradientBorder:
        //         !isFocused ? unfocusedBorder :
        //         isRemote ? remoteBorder :
        //         localBorder
        // )
        // .addAnimation(dependency: isRemote, duration: 0.3)
        // .addAnimation(dependency: isFocused, duration: 0.3)
        // .padding(.top, 8)
        // .padding(.horizontal, 12)
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
    
    private var placeholderTextFallback: String {
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

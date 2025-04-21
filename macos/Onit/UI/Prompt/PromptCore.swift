//
//  PromptCore.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import Defaults
import SwiftData
import SwiftUI

struct PromptCore: View {
    @Environment(\.windowState) private var state
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @Default(.mode) var mode
    
    let isEditing: Bool
    init(isEditing: Bool = false) { self.isEditing = isEditing }
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            if let pendingInput = state.pendingInput {
                InputView(input: pendingInput)
            }
            
            VStack(spacing: 6) {
                contextAndInput
                
                PromptCoreFooter()
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
    private var contextAndInput: some View {
        VStack(spacing: 8) {
            FileRow(contextList: state.pendingContextList)
            PromptInput().focused($isFocused)
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
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
}

// MARK: - Keyboard Arrow Key Listeners

extension PromptCore {
    var upListener: some View {
        Button {
            guard !chats.isEmpty else { return }

            if state.historyIndex + 1 < chats.count {
                state.historyIndex += 1
                state.currentChat = chats[state.historyIndex]
                state.currentPrompts = chats[state.historyIndex].prompts
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if state.historyIndex > 0 {
                state.historyIndex -= 1
                state.currentChat = chats[state.historyIndex]
                state.currentPrompts = chats[state.historyIndex].prompts
            } else if state.historyIndex == 0 {
                state.historyIndex = -1
                state.currentChat = nil
                state.currentPrompts = nil
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
    }
    
    var newListener: some View {
        Button {
            state.newChat()
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
}

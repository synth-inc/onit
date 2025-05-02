//
//  ToolbarAddButton.swift
//  Onit
//
//  Created by Kévin Naudin on 25/03/2025.
//

import SwiftUI

struct ToolbarAddButton: View {
    @Environment(\.windowState) private var state
    
    var body: some View {
        HStack(spacing: 0) {
            newChatButton
            systemPromptsButton
        }
    }
}

// MARK: - Child Components

extension ToolbarAddButton {
    private var newChatButton: some View {
        IconButton(
            icon: .circlePlus,
            iconSize: 22,
            action: { state.newChat() },
            tooltipPrompt: "New Chat",
            tooltipShortcut: .keyboardShortcuts(.newChat)
        )
    }
    
    private var systemPromptsButton: some View {
        IconButton(
            icon: .smallChevDown,
            action: {
                state.newChat()
                
                state.systemPromptState.shouldShowSelection = true
                state.systemPromptState.shouldShowSystemPrompt = true
            },
            tooltipPrompt: "Start new Chat with system prompt"
        )
        .onHover(perform: { isHovered in
            if isHovered && state.currentChat?.systemPrompt == nil && !state.systemPromptState.shouldShowSystemPrompt {
                state.systemPromptState.shouldShowSystemPrompt = true
            }
        })
    }
}

// MARK: - Preview

#Preview {
    ToolbarAddButton()
}

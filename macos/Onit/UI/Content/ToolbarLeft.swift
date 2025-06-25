//
//  ToolbarLeft.swift
//  Onit
//
//  Created by Kévin Naudin on 25/03/2025.
//

import SwiftUI

struct ToolbarLeft: View {
    @Environment(\.windowState) private var state
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            esc
            
            HStack(alignment: .center, spacing: 0) {
                newChatButton
                systemPromptsButton
            }
        }
    }
    
    private var esc: some View {
        TextButton(
            height: ToolbarButtonStyle.height,
            fillContainer: false,
            cornerRadius: ToolbarButtonStyle.cornerRadius,
            fontSize: 13,
            fontColor: .gray200,
            text: "ESC",
            tooltipPrompt: "Close Onit",
            tooltipShortcut: .keyboardShortcuts(.escape)
        ) {
            AnalyticsManager.Toolbar.escapePressed()
            PanelStateCoordinator.shared.closePanel()
        }
    }
    
    private var newChatButton: some View {
        IconButton(
            icon: .circlePlus,
            iconSize: 22,
            tooltipPrompt: "New Chat",
            tooltipShortcut: .keyboardShortcuts(.newChat)
        ) {
            AnalyticsManager.Toolbar.newChatPressed()
            state.newChat()
        }
    }
    
    private var systemPromptsButton: some View {
        IconButton(
            icon: .smallChevDown,
            tooltipPrompt: "Start new Chat with system prompt"
        ) {
            AnalyticsManager.Toolbar.systemPromptPressed()
            state.newChat()
            state.systemPromptState.shouldShowSelection = true
            state.systemPromptState.shouldShowSystemPrompt = true
        }
        .onHover(perform: { isHovered in
            if isHovered && state.currentChat?.systemPrompt == nil && !state.systemPromptState.shouldShowSystemPrompt {
                state.systemPromptState.shouldShowSystemPrompt = true
            }
        })
    }
}

// MARK: - Preview

#Preview {
    ToolbarLeft()
}

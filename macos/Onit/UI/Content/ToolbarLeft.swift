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
        HStack(alignment: .center, spacing: 4) {
            esc
            
            HStack(alignment: .center, spacing: 0) {
                newChatButton
                systemPromptsButton
            }
        }
    }
    
    private var esc: some View {
        Button {} label: {
            TextButton(
                height: ToolbarButtonStyle.height,
                fillContainer: false,
                cornerRadius: ToolbarButtonStyle.cornerRadius,
                fontSize: 11,
                fontWeight: .medium,
                fontColor: .gray200,
                text: "ESC",
                action: {
                    AnalyticsManager.Toolbar.escapePressed()
                    PanelStateCoordinator.shared.closePanel()
                }
            )
        }
        .tooltip(prompt: "Close Onit", shortcut: .keyboardShortcuts(.escape))
    }
    
    private var newChatButton: some View {
        IconButton(
            icon: .circlePlus,
            iconSize: 22,
            action: {
                AnalyticsManager.Toolbar.newChatPressed()
                state.newChat()
            },
            tooltipPrompt: "New Chat",
            tooltipShortcut: .keyboardShortcuts(.newChat)
        )
    }
    
    private var systemPromptsButton: some View {
        IconButton(
            icon: .smallChevDown,
            action: {
                AnalyticsManager.Toolbar.systemPromptPressed()
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
    ToolbarLeft()
}

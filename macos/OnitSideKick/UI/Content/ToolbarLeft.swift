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
            text: "ESC",
            colorConfig: .init(
                text: Color.S_2,
                background: Color.clear,
                hoverBackground: Color.T_8
            ),
            sizeConfig: .init(
                text: 11,
                horizontalPadding: 8,
                height: ToolbarButtonStyle.height,
                cornerRadius: ToolbarButtonStyle.cornerRadius
            ),
            tooltipConfig: .init(
                prompt: String.localized("Close Onit", table: "Sidekick"),
                shortcut: .keyboardShortcuts(.escape)
            )
        ) {
            AnalyticsManager.Toolbar.escapePressed()
            PanelStateCoordinator.shared.closePanel()
        }
        .padding(.trailing, 4)
    }

    private var newChatButton: some View {
        IconButton(
            icon: .circlePlus,
            iconSize: 22,
            tooltipPrompt: String.localized("New Chat", table: "Sidekick"),
            tooltipShortcut: .keyboardShortcuts(.newChat)
        ) {
            AnalyticsManager.Toolbar.newChatPressed()
            state?.newChat()
        }
    }

    private var systemPromptsButton: some View {
        IconButton(
            icon: .smallChevDown,
            tooltipPrompt: String.localized("Start new Chat with system prompt", table: "Sidekick")
        ) {
            AnalyticsManager.Toolbar.systemPromptPressed()
            state?.newChat()
            state?.systemPromptState.shouldShowSelection = true
            state?.systemPromptState.shouldShowSystemPrompt = true
        }
    }
}

// MARK: - Preview

#Preview {
    ToolbarLeft()
}

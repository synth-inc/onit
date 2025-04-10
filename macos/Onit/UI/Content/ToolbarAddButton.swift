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
            Button {
                state.newChat()
            } label: {
                Image(.circlePlus)
                    .renderingMode(.template)
                    .padding(2)
            }
            .tooltip(prompt: "New Chat", shortcut: .keyboardShortcuts(.newChat))
            
            Button {
                state.newChat()
                
                state.systemPromptState.shouldShowSelection = true
                state.systemPromptState.shouldShowSystemPrompt = true
            } label: {
                Image(.smallChevDown)
                    .renderingMode(.template)
                    .padding(2)
            }
            .onHover(perform: { isHovered in
                if isHovered && state.currentChat?.systemPrompt == nil && !state.systemPromptState.shouldShowSystemPrompt {
                    state.systemPromptState.shouldShowSystemPrompt = true
                }
            })
            .tooltip(prompt: "Start new Chat with system prompt")
        }
        .foregroundStyle(.gray200)
    }
}

#Preview {
    ToolbarAddButton()
}

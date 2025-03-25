//
//  ToolbarAddButton.swift
//  Onit
//
//  Created by Kévin Naudin on 25/03/2025.
//

import SwiftUI

struct ToolbarAddButton: View {
    @Environment(\.model) var model
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.newChat()
            } label: {
                Image(.circlePlus)
                    .renderingMode(.template)
                    .padding(2)
            }
            .tooltip(prompt: "New Chat", shortcut: .keyboardShortcuts(.newChat))
            
            Button {
                model.newChat()
                
                SystemPromptState.shared.shouldShowSelection = true
                SystemPromptState.shared.shouldShowSystemPrompt = true
            } label: {
                Image(.smallChevDown)
                    .renderingMode(.template)
                    .padding(2)
            }
            .onHover(perform: { isHovered in
                if isHovered && model.currentChat?.systemPrompt == nil && !SystemPromptState.shared.shouldShowSystemPrompt {
                    SystemPromptState.shared.shouldShowSystemPrompt = true
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

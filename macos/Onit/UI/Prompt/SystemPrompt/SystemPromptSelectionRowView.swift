//
//  SystemPromptSelectionRowView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct SystemPromptSelectionRowView: View {
    @Default(.systemPromptId) var systemPromptId
    
    var prompt: SystemPrompt
    
    var body: some View {
        Button(action: {
            systemPromptId = prompt.id
            prompt.lastUsed = Date()
            SystemPromptState.shared.userSelectedPrompt = true
        }) {
            HStack {
                Text(prompt.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let shortcut = KeyboardShortcuts.Name(prompt.id).shortcut?.native {
                    KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.gray200)
                }
            }
            .padding(8)
        // Use .black and not .clear because only text will be clickable
            .background(systemPromptId == prompt.id ? .gray700 : Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
    #Preview {
        SystemPromptSelectionRowView(prompt: PreviewSampleData.systemPrompt)
    }
#endif

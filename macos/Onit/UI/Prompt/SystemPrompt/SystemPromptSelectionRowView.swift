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
    @Environment(\.windowState) var windowState
    
    var prompt: SystemPrompt
    
    var body: some View {
        Button(action: {
            prompt.lastUsed = Date()
            windowState.systemPromptId = prompt.id
            windowState.systemPromptState.userSelectedPrompt = true
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
            .background(windowState.systemPromptId == prompt.id ? .gray700 : Color.black)
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

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
        let isSelected: Bool = windowState.systemPromptId == prompt.id
        
        TextButton(
            text: prompt.name,
            selected: isSelected,
            action: selectPrompt
        ) {
            if let shortcut = KeyboardShortcuts.Name(prompt.id).shortcut?.native {
                KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.gray200)
            }
        }
    }
}

// MARK: - Private Functions

extension SystemPromptSelectionRowView {
    func selectPrompt() {
        prompt.lastUsed = Date()
        windowState.systemPromptId = prompt.id
        windowState.systemPromptState.userSelectedPrompt = true
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        SystemPromptSelectionRowView(prompt: PreviewSampleData.systemPrompt)
    }
#endif

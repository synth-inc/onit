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
        TextButton(
            text: prompt.name,
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
        systemPromptId = prompt.id
        prompt.lastUsed = Date()
        SystemPromptState.shared.userSelectedPrompt = true
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        SystemPromptSelectionRowView(prompt: PreviewSampleData.systemPrompt)
    }
#endif

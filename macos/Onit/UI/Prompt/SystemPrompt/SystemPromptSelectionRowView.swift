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
        ActionButton(
            action: selectPrompt,
            text: prompt.name
        ) {
            if let shortcut = KeyboardShortcuts.Name(prompt.id).shortcut?.native {
                KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.gray200)
            }
        }
    }
}

/// Private Functions
extension SystemPromptSelectionRowView {
    func selectPrompt() {
        systemPromptId = prompt.id
        prompt.lastUsed = Date()
        SystemPromptState.shared.userSelectedPrompt = true
    }
}

#if DEBUG
    #Preview {
        SystemPromptSelectionRowView(prompt: PreviewSampleData.systemPrompt)
    }
#endif

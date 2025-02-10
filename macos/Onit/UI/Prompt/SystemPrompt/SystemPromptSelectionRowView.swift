//
//  SystemPromptSelectionRowView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import Defaults
import SwiftUI

struct SystemPromptSelectionRowView: View {
    @Default(.systemPromptId) var systemPromptId
    
    var prompt: SystemPrompt
    
    var body: some View {
        Button(action: {
            systemPromptId = prompt.id
        }) {
            Text(prompt.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            // Use .black and not .clear because only text will be clickable
                .background(systemPromptId == prompt.id ? .gray700 : Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SystemPromptSelectionRowView(prompt: PreviewSampleData.systemPrompt)
}

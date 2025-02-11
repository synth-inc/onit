//
//  GeneratedSystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

import SwiftUI

struct GeneratedSystemPromptView: View {
    @State var isExpanded: Bool = false
    
    var systemPrompt: SystemPrompt
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                Image(.chatSettings)
                    .renderingMode(.template)
                Text(systemPrompt.name)
                    .lineLimit(1)
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(.smallChevDown)
                        .renderingMode(.template)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(DarkerButtonStyle())
            }
            .foregroundStyle(.blue300)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Prompt")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(systemPrompt.prompt)
                        .foregroundStyle(.gray100)
                }
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .fill(.gray600)
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    GeneratedSystemPromptView(isExpanded: true, systemPrompt: SystemPrompt.outputOnly)
}

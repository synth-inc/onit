//
//  PromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PromptView: View {
    @Environment(\.model) var model
    let prompt: Prompt

    var body: some View {
        VStack(spacing: 0) {
            // User's prompt
            Text(prompt.text)
                .appFont(.medium14)
                .foregroundStyle(.FG)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(.gray800, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.gray500)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            
            // AI responses
            ForEach(prompt.responses) { response in
                Text(response.text)
                    .appFont(.medium14)
                    .foregroundStyle(.FG)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(.gray700, in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.gray400)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PromptView(prompt: Prompt(input: nil, text: "Hello, how are you?", timestamp: Date()))
}

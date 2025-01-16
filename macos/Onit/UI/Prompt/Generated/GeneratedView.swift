//
//  GeneratedView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedView: View {
    var prompt: Prompt

    var body: some View {
        UserInputView(prompt: prompt)
        content
    }

    var content: some View {
        VStack(spacing: 16) {
            if !prompt.responses.isEmpty {
                GeneratedContentView(result: prompt.responses[prompt.generationIndex].text)
            }
            GeneratedToolbar(prompt: prompt)
                .padding(.horizontal, 16)
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
//        GeneratedView(prompt: Prompt(input: nil, text: "Testing this out", timestamp: Date(), responses: [Response(text: "Testing this out")]))
    }
}
#endif

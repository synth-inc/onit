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
        VStack(alignment: .leading, spacing: 0) {
            FinalContextView(prompt: prompt)
            content
        }
    }

    var content: some View {
        VStack(spacing: 16) {
            if !prompt.responses.isEmpty {
                let curResponse = prompt.responses[prompt.generationIndex]
                if curResponse.type == .success {
                    GeneratedContentView(result: prompt.responses[prompt.generationIndex].text)
                } else if (curResponse.type == .error) {
                    GeneratedErrorView(errorDescription: prompt.responses[prompt.generationIndex].text)
                }
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

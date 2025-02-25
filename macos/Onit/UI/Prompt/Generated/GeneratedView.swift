//
//  GeneratedView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedView: View {
    @Environment(\.model) var model
    
    var prompt: Prompt

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FinalContextView(prompt: prompt)
            content
        }
    }

    var content: some View {
        VStack(spacing: 16) {
            if case .generating = prompt.generationState {
                GeneratingView()
            } else if !prompt.responses.isEmpty {
                let curResponse = prompt.responses[prompt.generationIndex]
                switch curResponse.type {
                case .error:
                    GeneratedErrorView(errorDescription: prompt.responses[prompt.generationIndex].text)
                default:
                    GeneratedContentView(prompt: prompt)
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

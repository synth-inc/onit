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
        VStack(spacing: 0) {
            if !prompt.responses.isEmpty {
                let curResponse = prompt.sortedResponses[prompt.generationIndex]
                
                switch curResponse.type {
                case .error:
                    GeneratedErrorView(errorDescription: prompt.sortedResponses[prompt.generationIndex].text)
                default:
                    GeneratedContentView(prompt: prompt)
                }
            }
            
            if prompt.generationState == .done {
                GeneratedToolbar(prompt: prompt)
            }
        }
    }
}

#if DEBUG
    #Preview {
        var prompt = Prompt.sample
        prompt.input = Input(selectedText: "blablabla", application: "Xcode")
        
        return GeneratedView(prompt: prompt)
    }
#endif

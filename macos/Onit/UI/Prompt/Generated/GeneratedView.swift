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
                let safeIndex = prompt.safeGenerationIndex
                if safeIndex >= 0 && safeIndex < prompt.sortedResponses.count {
                    let curResponse = prompt.sortedResponses[safeIndex]
                    
                    switch curResponse.type {
                    case .error:
                        GeneratedErrorView(errorDescription: curResponse.text)
                    default:
                        GeneratedContentView(prompt: prompt)
                    }
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

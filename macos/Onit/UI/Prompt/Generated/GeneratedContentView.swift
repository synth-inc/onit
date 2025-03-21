//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import LLMStream
import SwiftUI

struct GeneratedContentView: View {
    @Environment(\.model) var model
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight

    var prompt: Prompt
    
    var isPartial: Bool {
        let response = prompt.responses[prompt.generationIndex]
        
        return response.isPartial
    }
    
    var textToRead: String {
        let response = prompt.responses[prompt.generationIndex]
        
        return response.isPartial ? model.streamedResponse : response.text
    }
    
    var configuration: LLMStreamConfiguration {
        let thought = ThoughtConfiguration(icon: Image(.lightBulb))
        
        return LLMStreamConfiguration(thought: thought)
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            LLMStreamView(text: textToRead, configuration: configuration, onCodeAction: codeAction)
                .padding(.horizontal, 16)
            Spacer()
            if textToRead.isEmpty {
                HStack {
                    Spacer()
                    QLImage("loader_rotated-200")
                        .frame(width: 36, height: 36)
                        .padding(.horizontal, 16)
                    Spacer()
                }
            }
        }
    }
    
    private func codeAction(code: String) {
        
    }
}

#Preview {
    GeneratedContentView(prompt: Prompt.sample)
}

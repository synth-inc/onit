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
    @Environment(\.windowState) private var state
    @Environment(\.openURL) var openURL
    
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight

    var prompt: Prompt
    
    var textToRead: String {
        let safeIndex = prompt.safeGenerationIndex
        guard safeIndex >= 0 && safeIndex < prompt.sortedResponses.count else {
            return ""
        }
        let response = prompt.sortedResponses[safeIndex]
        return response.isPartial ? (state?.streamedResponse ?? "") : response.text
    }
    
    var configuration: LLMStreamConfiguration {
        let font = FontConfiguration(size: fontSize, lineHeight: lineHeight)
        let color = ColorConfiguration(citationBackgroundColor: .gray600,
                                       citationHoverBackgroundColor: .gray400,
                                       citationTextColor: .gray100)
        let thought = ThoughtConfiguration(icon: Image(.lightBulb))
        
        return LLMStreamConfiguration(font: font, colors: color, thought: thought)
    }
    

    var body: some View {
        // By reading fontSize and lineHeight here, we ensure SwiftUI observes them.
        let _ = fontSize
        let _ = lineHeight

        VStack(alignment: .leading, spacing: 8) {
            LLMStreamView(text: textToRead,
                        configuration: configuration,
                        onUrlClicked: onUrlClicked,
                        onCodeAction: codeAction)
                .id("\(fontSize)-\(lineHeight)") // Force recreation when font settings change
                .padding(.horizontal, 12)

            if let response = prompt.currentResponse, response.hasToolCall {
                ToolCallView(response: response)
                    .padding(.horizontal, 12)
            }

            Spacer()
            if textToRead.isEmpty && !(state?.isSearchingWeb[prompt.id] ?? false) && prompt.currentResponse?.hasToolCall != true {
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

    private func onUrlClicked(urlString: String) {
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private func codeAction(code: String) {
        
    }
}

#Preview {
    GeneratedContentView(prompt: Prompt.sample)
}

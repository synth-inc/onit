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
        return response.isPartial ? state.streamedResponse : response.text
    }
    
    var configuration: LLMStreamConfiguration {
        let color = ColorConfiguration(citationBackgroundColor: .gray600,
                                       citationHoverBackgroundColor: .gray400,
                                       citationTextColor: .gray100)
        let thought = ThoughtConfiguration(icon: Image(.lightBulb))
        let code = CodeBlockConfiguration(showActionButton: true,
                                          actionButtonIcon: Image(.notes),
                                          actionButtonTooltip: "Open in notepad")
        let citation = CitationConfiguration(
            backgroundColor: .gray600,
            hoverBackgroundColor: .gray400,
            textColor: .gray100,
            hoverTextColor: .white,
            borderRadius: 6,
            padding: EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4),
            margin: EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        )
        
        return LLMStreamConfiguration(colors: color,
									  thought: thought,
                                      codeBlock: code,
                                      citation: citation)
    }
    
    var body: some View {

        VStack(alignment: .leading, spacing: 8) {
            LLMStreamView(text: textToRead,
                          configuration: configuration,
                          onUrlClicked: onUrlClicked,
                          onCodeAction: codeAction)
                .padding(.horizontal, 12)

            if let response = currentResponse, response.hasToolCall {
                ToolCallView(response: response)
                    .padding(.horizontal, 12)
            }

            Spacer()
            if textToRead.isEmpty && !(state.isSearchingWeb[prompt.id] ?? false) && currentResponse?.hasToolCall != true {
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
    
    private var currentResponse: Response? {
        guard prompt.generationIndex >= 0,
              prompt.generationIndex < prompt.sortedResponses.count else {
            return nil
        }
        return prompt.sortedResponses[prompt.generationIndex]
    }

    private func onUrlClicked(urlString: String) {
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private func codeAction(code: String) {
        let notepadConfig = model.getNotepadConfig(prompt: prompt)
        
        NotepadWindowController.shared.showWindow(
            oldText: notepadConfig.oldText,
            newText: code,
            isStreaming: notepadConfig.isStreaming
        )
    }
}

#Preview {
    GeneratedContentView(prompt: Prompt.sample)
}

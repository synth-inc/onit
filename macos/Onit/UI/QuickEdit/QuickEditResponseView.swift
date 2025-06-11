//
//  QuickEditResponseView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/06/2025.
//

import SwiftUI
import Defaults
import LLMStream

struct QuickEditResponseView: View {
    @Environment(\.windowState) private var state
    @Environment(\.openURL) var openURL
    
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    
    let prompt: Prompt
    
    private var textToDisplay: String {
        guard !prompt.responses.isEmpty else {
            return state.streamedResponse
        }
        
        let response = prompt.sortedResponses[prompt.generationIndex]
        return response.isPartial ? state.streamedResponse : response.text
    }
    
    private var configuration: LLMStreamConfiguration {
        let color = ColorConfiguration(citationBackgroundColor: .gray600,
                                       citationHoverBackgroundColor: .gray400,
                                       citationTextColor: .gray100)
        let thought = ThoughtConfiguration(icon: Image(.lightBulb))
        
        return LLMStreamConfiguration(colors: color, thought: thought)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            promptSection
            
            responseSection
            
            if prompt.generationState == .done {
                generatedToolbar
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Components

extension QuickEditResponseView {
    
    private var promptSection: some View {
        Text(prompt.instruction)
            .appFont(.medium13)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(8)
            .background(.gray700)
            .addBorder(cornerRadius: 8, lineWidth: 1, stroke: .gray500)
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch prompt.generationState {
            case .generating:
                HStack(spacing: 8) {
                    LoaderPulse()
                        .frame(width: 16, height: 16)
                    
                    Text("Generating...")
                        .appFont(.medium13)
                        .foregroundColor(.gray300)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            case .streaming, .done:
                if textToDisplay.isEmpty && !(state.isSearchingWeb[prompt.id] ?? false) {
                    HStack {
                        Spacer()
                        QLImage("loader_rotated-200")
                            .frame(width: 36, height: 36)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                } else {
                    ScrollView {
                        LLMStreamView(
                            text: textToDisplay,
                            configuration: configuration,
                            onUrlClicked: onUrlClicked,
                            onCodeAction: codeAction
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .mask(
                        VStack(spacing: 0) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                            
                            Color.white
                            
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                        }
                    )
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    private var generatedToolbar: some View {
        HStack(spacing: 8) {
            if let generation = prompt.generation {
                CopyButton(text: generation, stripMarkdown: true)
            }
            
            IconButton(
                icon: .arrowsSpin,
                action: {
                    state.generate(prompt)
                },
                tooltipPrompt: "Retry"
            )
        }
    }
}

// MARK: - Actions

extension QuickEditResponseView {
    
    private func onUrlClicked(urlString: String) {
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private func codeAction(code: String) {
        // TODO: Implement code action if needed
    }
}

#Preview {
    QuickEditResponseView(prompt: Prompt.sample)
        .background(.black)
} 

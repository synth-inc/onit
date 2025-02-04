//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import MarkdownUI
import SwiftUI

struct GeneratedContentView: View {
    @Environment(\.model) var model
    @State private var contentHeight: CGFloat = 1000
    
    var prompt: Prompt
    
    var textToRead: String {
        let response = prompt.responses[prompt.generationIndex]
        
        return if response.isPartial {
            model.streamedResponse
        } else {
            response.text
        }
    }
    
    var height: CGFloat {
        min(contentHeight, 500)
    }

    var body: some View {
        Markdown(textToRead)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            contentHeight = proxy.size.height
                        }
                }
            }
    }
}

extension Theme {
    @MainActor static var custom: Theme {
        @Default(.fontSize) var fontSize

        return Theme()
            .text {
                FontFamily(.custom("Inter"))
                FontSize(fontSize)
                ForegroundColor(.FG)
            }
            .code {
                FontFamily(.custom("SometypeMono"))
                FontFamilyVariant(.monospaced)
                FontSize(fontSize)
                ForegroundColor(.pink)
            }
            .codeBlock { configuration in
                CodeBlockView(configuration: configuration)
            }
    }
}

#Preview {
    GeneratedContentView(prompt: Prompt.sample)
}

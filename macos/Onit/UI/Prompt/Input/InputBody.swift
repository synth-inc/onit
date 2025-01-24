//
//  InputBody.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI
import HighlightSwift
import MarkdownUI

struct InputBody: View {
    @Environment(\.model) var model
    @Binding var inputExpanded: Bool
    @State var textHeight: CGFloat = 0
    
    var input: Input

    var height: CGFloat {
        min(textHeight, 73)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            textView
            ScrollView {
                textView
            }
        }
        .frame(height: inputExpanded ? height : 0)
    }
    
    var textView: some View {
        Markdown(formattedText)
            .markdownTheme(customTheme)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            textHeight = proxy.size.height
                        }
                }
            }
    }
    
    private let customTheme = Theme()
        .text {
            FontFamily(.custom("Inter"))
            FontSize(16)
            ForegroundColor(.FG)
        }
        .code {
            FontFamily(.custom("SometypeMono"))
            FontFamilyVariant(.monospaced)
            ForegroundColor(.pink)
        }
        .codeBlock { configuration in
            if let language = configuration.language,
               let language = HighlightLanguage.language(for: language) {
                CodeText(configuration.content)
                    .codeFont(AppFont.code.nsFont)
                    .highlightLanguage(language)
            } else {
                CodeText(configuration.content)
            }
        }
    
    private var formattedText: String {
        "```\n" + input.selectedText + "\n```"
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        InputBody(inputExpanded: .constant(true), input: .sample)
    }
}
#endif

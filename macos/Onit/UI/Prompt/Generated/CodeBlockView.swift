//
//  CodeBlockView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftUI
import MarkdownUI
import HighlightSwift

struct CodeBlockView: View {
    var configuration: CodeBlockConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let language = configuration.language {
                    Text(language)
                        .appFont(.medium13)
                }

                Spacer()
            }
            .foregroundStyle(.gray100)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            Color.gray700
                .frame(height: 1)

            ViewThatFits(in: .vertical) {
                ScrollView(.horizontal) {
                    textView
                }
                ScrollView([.horizontal, .vertical]) {
                    textView
                }
            }
            .frame(maxHeight: 150)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.gray700)
        }
    }

    @ViewBuilder
    var textView: some View {
        ZStack(alignment: .topLeading) {
            Spacer()
                .containerRelativeFrame([.horizontal, .vertical])

            Group {
                if let language = configuration.language,
                   let language = HighlightLanguage.language(for: language) {
                    CodeText(configuration.content)
                        .highlightLanguage(language)
                } else {
                    CodeText(configuration.content)
                }
            }
            .appFont(.code)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .padding(.top, 12)
        }
    }
}


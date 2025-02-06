//
//  CodeBlockView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import HighlightSwift
import MarkdownUI
import SwiftUI

struct CodeBlockView: View {
    var configuration: CodeBlockConfiguration

    var rect: RoundedRectangle {
        .rect(cornerRadius: 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            top

            Color.gray700
                .frame(height: 1)

            bottom
        }
        .overlay {
            rect
                .strokeBorder(.gray700)
        }
        .clipShape(rect)
    }

    var top: some View {
        HStack {
            if let language = configuration.language {
                Text(language)
                    .appFont(.medium13)
            }

            Spacer()

            copyButton
        }
        .foregroundStyle(.gray100)
        .padding(.vertical, 2)
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    var copyButton: some View {
        CopyButton(text: configuration.content)
    }

    var bottom: some View {
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

    @ViewBuilder
    var textView: some View {
        ZStack(alignment: .topLeading) {
            Spacer()
                .containerRelativeFrame(.horizontal)

            Group {
                if let language = configuration.language,
                    let language = HighlightLanguage.language(for: language)
                {
                    CodeText(configuration.content)
                        .codeFont(AppFont.code.nsFont)
                        .highlightLanguage(language)
                } else {
                    CodeText(configuration.content)
                }
            }
            .environment(\.colorScheme, .dark)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .padding(.top, 12)
        }
    }
}

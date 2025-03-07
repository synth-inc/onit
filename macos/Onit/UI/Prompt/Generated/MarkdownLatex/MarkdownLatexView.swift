//
//  MarkdownLatexView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import SwiftUI

struct MarkdownLatexView: NSViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let lineHeight: CGFloat
    
    func makeNSView(context: Self.Context) -> MarkdownLatexTextView {
        let view = MarkdownLatexTextView(
            text: text,
            fontSize: fontSize,
            lineHeight: lineHeight
        )
        return view
    }
    
    func updateNSView(_ nsView: MarkdownLatexTextView, context: Self.Context) {
        nsView.setText(text)
    }
}

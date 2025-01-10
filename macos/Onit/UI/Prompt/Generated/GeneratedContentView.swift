//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI
import MarkdownUI

struct GeneratedContentView: View {
    @Environment(\.model) var model
    @State private var text: String = ""
    private var stream: Bool = false
    
    init(result: String) {
        self._text = State(initialValue: result)
    }
    
    init(text: String) {
        self._text = State(initialValue: text)
    }
    
    init(stream: Bool) {
        self.stream = stream
        self._text = State(initialValue: model.streamedResponse)
    }

    var body: some View {
        Markdown(self.text)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: model.streamedResponse) { newValue in
                if self.stream {
                    self.text = newValue
                }
            }
    }
}

extension Theme {
    @MainActor static let custom = Theme()
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
            CodeBlockView(configuration: configuration)
        }
}

#Preview {
    GeneratedContentView(result: "")
}

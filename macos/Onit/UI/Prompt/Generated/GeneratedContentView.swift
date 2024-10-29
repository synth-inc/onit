//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI
import MarkdownUI

struct GeneratedContentView: View {
    var result: String

    var body: some View {
        Markdown(result)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
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
    GeneratedContentView(result: """
```swift
struct ContentView: View {
    var body: some View {
        Text("Hello world")
    }
}
```
"""
    )
}

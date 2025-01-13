//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI
import MarkdownUI

struct GeneratedContentView: View {
    @State private var contentHeight: CGFloat = 1000

    var result: String

    var height: CGFloat {
        min(contentHeight, 500)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
        }
        .frame(height: height)
    }

    var content: some View {
        Markdown(result)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
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

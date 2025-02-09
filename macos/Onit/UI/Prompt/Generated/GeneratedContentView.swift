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

    var result: String

    var height: CGFloat {
        min(contentHeight, 500)
    }

    var body: some View {
        //        ViewThatFits(in: .vertical) {
        content
        //            ScrollView {
        //                content
        //            }
        //        }
        //        .frame(height: height)
    }

    var content: some View {
        ScrollView {
            Markdown(result)
                .markdownTheme(.custom)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
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
        .frame(maxHeight: height)
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
    GeneratedContentView(
        result: """
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

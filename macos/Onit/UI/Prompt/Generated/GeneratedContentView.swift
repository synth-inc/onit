//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import MarkdownUI
import SwiftUI

struct GeneratedContentView: View {
    @Environment(\.model) var model
    @State private var contentHeight: CGFloat = 1000
    @Default(.lineHeight) var lineHeight
    @Default(.fontSize) var fontSize
    
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
        Markdown(result)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .lineSpacing((lineHeight * fontSize) - fontSize)
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
        @Default(.lineHeight) var lineHeight
        
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
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: fontSize + (lineHeight * fontSize) - fontSize) // This works
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

//
//  InputBody.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import HighlightSwift
import SwiftUI

struct InputBody: View {
    @Binding var inputExpanded: Bool
    @State var text: String?
    @State var textHeight: CGFloat = 0

    var input: Input

    init(inputExpanded: Binding<Bool>, input: Input) {
        _inputExpanded = inputExpanded
        text = input.selectedText.count <= 500 ? input.selectedText : nil
        self.input = input
    }

    var height: CGFloat {
        min(textHeight, 222)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            if let text = text {
                textView(text: text)
                ScrollView {
                    textView(text: text)
                }
            } else {
                ProgressView("Loading highlighted text...")
                    .controlSize(.small)
                    .padding(.vertical, 16)
                    .background {
                        geometryReader
                    }
            }
        }
        .frame(height: inputExpanded ? height : 0)
        .onChange(of: input.selectedText, initial: true) {
            DispatchQueue.main.async {
                text = input.selectedText
            }
        }
    }

    func textView(text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .foregroundColor(.FG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .padding(10)
            .background {
                geometryReader
            }
    }

    var geometryReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    textHeight = proxy.size.height
                }
        }
    }
}

#if DEBUG
    #Preview {
        InputBody(inputExpanded: .constant(true), input: .sample)
    }
#endif

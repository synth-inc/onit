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

    var body: some View {
        Group {
            if let text = text {
                if inputExpanded {
                    textScrollView(text)
                }
            } else {
                loader
            }
        }
        .onChange(of: input.selectedText, initial: true) {
            DispatchQueue.main.async {
                text = input.selectedText
            }
        }
    }
}

// MARK: - Child Components

extension InputBody {
    private func textScrollView(_ text: String) -> some View {
        ScrollView {
            Text(text)
                .styleText(size: 13, weight: .regular)
                .padding(.top, 4)
                .padding([.horizontal, .bottom], 12)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                textHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size.height) { _, newHeight in
                                textHeight = newHeight
                            }
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: min(textHeight, 222))
    }
    
    private var loader: some View {
        VStack(alignment: .center, spacing: 12) {
            ProgressView()
                .controlSize(.small)
            
            Text("Loading highlighted text...")
                .styleText(size: 13, weight: .regular)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

#if DEBUG
    #Preview {
        InputBody(inputExpanded: .constant(true), input: .sample)
    }
#endif

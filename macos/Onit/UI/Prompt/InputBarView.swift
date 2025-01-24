//
//  InputBarView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import SwiftUI

struct InputBarView: View {
    @Environment(\.model) var model

    var body: some View {
        VStack(spacing: 0) {
            if model.currentPrompts?.count ?? 0 > 0 {
                PromptDivider()
            }
            if let pendingInput = model.pendingInput {
                InputView(input: pendingInput)
            }
            FileRow(contextList: model.pendingContextList, isSent: false)
            TextInputView()
        }
        .background {
            heightListener
        }
    }

    var heightListener: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    model.inputHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, new in
                    model.inputHeight = new
                }
        }
    }
}

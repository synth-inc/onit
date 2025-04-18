//
//  InputBarView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import SwiftUI

struct InputBarView: View {
    @Environment(\.model) var model
    
    private var shouldShowSystemPrompt: Bool {
        model.currentChat?.systemPrompt == nil && SystemPromptState.shared.shouldShowSystemPrompt
    }

    var body: some View {
        VStack(spacing: 0) {
            if model.currentPrompts?.count ?? 0 > 0 {
                PromptDivider()
            }
            if let pendingInput = model.pendingInput {
                InputView(input: pendingInput)
            }
            if shouldShowSystemPrompt {
                SystemPromptView()
            }
            FileRow(contextList: model.pendingContextList)
            TextInputView()
        }
        .background {
            heightListener
        }
        .border(.red, width: 4)
    }

    var heightListener: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    model.inputHeight = proxy.size.height
//                    model.adjustPanelSize()
                }
                .onChange(of: proxy.size.height) { _, new in
                    model.inputHeight = new
//                    model.adjustPanelSize()
                }
        }
    }
}

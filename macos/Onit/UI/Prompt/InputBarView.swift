//
//  InputBarView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import SwiftUI

struct InputBarView: View {
    @Environment(\.windowState) private var state
    
    private var shouldShowSystemPrompt: Bool {
        state.currentChat?.systemPrompt == nil && state.systemPromptState.shouldShowSystemPrompt
    }

    var body: some View {
        VStack(spacing: 0) {
            if state.currentPrompts?.count ?? 0 > 0 {
                PromptDivider()
            }
            if let pendingInput = state.pendingInput {
                InputView(input: pendingInput)
            }
            if shouldShowSystemPrompt {
                SystemPromptView()
            }
            FileRow(contextList: state.pendingContextList)
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
                    state.inputHeight = proxy.size.height
                    state.panel?.adjustSize()
                }
                .onChange(of: proxy.size.height) { _, new in
                    state.inputHeight = new
                    state.panel?.adjustSize()
                }
        }
    }
}

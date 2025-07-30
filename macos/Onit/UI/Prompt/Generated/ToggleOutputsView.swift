//
//  ToggleOutputsView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftUI

struct ToggleOutputsView: View {
    @Environment(\.windowState) var windowState
    
    var prompt: Prompt

    private var isTyping: Bool { windowState?.isTyping ?? false }
    
    var body: some View {
        HStack(spacing: 0) {
            `left`
            text
            `right`
        }
        .foregroundStyle(Color.S_2)
    }

    var left: some View {
        Button {
            decrementGenerationIndex()
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevLeft)
                        .renderingMode(.template)
                }
        }
        .foregroundStyle(prompt.canDecrementGeneration ? Color.S_0 : Color.S_2)
        .disabled(!prompt.canDecrementGeneration)
        .background {
            if isTyping {
                Button { decrementGenerationIndex() }
                label: { EmptyView() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
            }
        }
    }

    @ViewBuilder
    var text: some View {
        if let total = prompt.generationCount {
            Text("\(prompt.generationIndex + 1)/\(total)")
                .appFont(.medium14)
                .monospacedDigit()
        }
    }

    var right: some View {
        Button {
            incrementGenerationIndex()
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevRight)
                        .renderingMode(.template)
                }
        }
        .foregroundStyle(prompt.canIncrementGeneration ? Color.S_0 : Color.S_2)
        .disabled(!prompt.canIncrementGeneration)
        .background {
            if isTyping {
                Button { incrementGenerationIndex() }
                label: { EmptyView() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
            }
        }
    }
}

// MARK: - Private Functions

extension ToggleOutputsView {
    private func decrementGenerationIndex() {
        if prompt.generationIndex > 0 {
            prompt.updateGenerationIndex(prompt.generationIndex - 1)
        }
    }
    
    private func incrementGenerationIndex() {
        if let total = prompt.generationCount,
           prompt.generationIndex + 1 < total
        {
            prompt.updateGenerationIndex(prompt.generationIndex + 1)
        }
    }
}

#if DEBUG
    #Preview {
        //        ToggleOutputsView()
    }
#endif

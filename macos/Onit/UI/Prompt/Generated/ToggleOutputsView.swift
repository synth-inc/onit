//
//  ToggleOutputsView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftUI

struct ToggleOutputsView: View {
//    @Environment(\.model) var model
    var prompt: Prompt
    
    var body: some View {
        HStack(spacing: 0) {
            `left`
            text
            `right`
        }
        .foregroundStyle(.gray300)
    }

    var left: some View {
        Button {
            prompt.generationIndex -= 1
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevLeft)
                }
        }
        .keyboardShortcut(.leftArrow, modifiers: [])
        .foregroundStyle(prompt.canDecrementGeneration ? .FG : .gray300)
        .disabled(!prompt.canDecrementGeneration)
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
            prompt.generationIndex += 1
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevRight)
                }
        }
        .keyboardShortcut(.rightArrow, modifiers: [])
        .foregroundStyle(prompt.canIncrementGeneration ? .FG : .gray300)
        .disabled(!prompt.canIncrementGeneration)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
//        ToggleOutputsView()
    }
}
#endif

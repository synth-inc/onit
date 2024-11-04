//
//  ToggleOutputsView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftUI

struct ToggleOutputsView: View {
    @Environment(\.model) var model

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
            model.generationIndex -= 1
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevLeft)
                }
        }
        .keyboardShortcut(.leftArrow, modifiers: [])
        .foregroundStyle(model.canDecrementGeneration ? .FG : .gray300)
        .disabled(!model.canDecrementGeneration)
    }

    @ViewBuilder
    var text: some View {
        if let total = model.generationCount {
            Text("\(model.generationIndex + 1)/\(total)")
                .appFont(.medium14)
                .monospacedDigit()
        }
    }

    var right: some View {
        Button {
            model.generationIndex += 1
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevRight)
                }
        }
        .keyboardShortcut(.rightArrow, modifiers: [])
        .foregroundStyle(model.canIncrementGeneration ? .FG : .gray300)
        .disabled(!model.canIncrementGeneration)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        ToggleOutputsView()
    }
}
#endif

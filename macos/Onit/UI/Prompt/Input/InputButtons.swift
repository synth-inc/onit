//
//  InputButtons.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import Defaults
import SwiftUI

struct InputButtons: View {
    @Environment(\.windowState) private var state
    
    @Binding var inputExpanded: Bool

    var input: Input
    var isEditing: Bool

    var body: some View {
        Group {
            if let state = state, input == state.selectedPendingInput {
                Button {
                    clearHighlightedText(state: state)
                    
                    state.selectedPendingInput = nil
                } label: {
                    Image(.smallRemove)
                        .renderingMode(.template)
                }
                .buttonStyle(DarkerButtonStyle())
            }

            Button {
                if isEditing {
                    Defaults[.showHighlightedTextInput] = false
                } else {
                    inputExpanded.toggle()
                }
            } label: {
                Color.clear
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(.smallChevRight)
                            .renderingMode(.template)
                            .rotationEffect(isEditing ? .degrees(90) : inputExpanded ? .degrees(90) : .zero)
                    }
            }
        }
        .foregroundStyle(.gray200)
    }

    // MARK: - Private Functions

    private func clearHighlightedText(state: OnitPanelState) {
        if state.selectedPendingInput == state.unpinnedPendingInput {
            state.unpinnedPendingInput = nil
        }
    }
}

#if DEBUG
    #Preview {
        InputButtons(inputExpanded: .constant(true), input: .sample, isEditing: true)
    }
#endif

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

            CopyButton(text: input.selectedText)
                .frame(width: 20, height: 20)

            Button {
                inputExpanded.toggle()
            } label: {
                Color.clear
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(.smallChevRight)
                            .renderingMode(.template)
                            .rotationEffect(inputExpanded ? .degrees(90) : .zero)
                    }
            }
            
            closeButton
        }
        .foregroundStyle(.gray200)
    }
    
    // MARK: - Child Components
    
    private var closeButton: some View {
        IconButton(
            icon: .cross,
            iconSize: 9
        ) {
            Defaults[.showHighlightedTextInput] = false
        }
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
        InputButtons(inputExpanded: .constant(true), input: .sample)
    }
#endif

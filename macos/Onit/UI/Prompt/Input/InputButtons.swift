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
            if let state = state, input == state.pendingInput {
                Button {
                    state.pendingInput = nil
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
}

#if DEBUG
    #Preview {
        InputButtons(inputExpanded: .constant(true), input: .sample, isEditing: true)
    }
#endif

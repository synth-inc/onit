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

    var input: Input

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
                Defaults[.showHighlightedTextInput] = false
            } label: {
                Color.clear
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(.smallChevRight)
                            .renderingMode(.template)
                            .rotationEffect(.degrees(90))
                    }
            }
        }
        .foregroundStyle(.gray200)
    }
}

#if DEBUG
    #Preview {
        InputButtons(input: .sample)
    }
#endif

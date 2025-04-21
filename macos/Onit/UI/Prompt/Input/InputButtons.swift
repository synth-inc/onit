//
//  InputButtons.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import SwiftUI

struct InputButtons: View {
    @Environment(\.windowState) private var state
    
    @Binding var inputExpanded: Bool

    var input: Input

    var body: some View {
        @Bindable var state = state

        Group {
            if input == state.pendingInput {
                Button {
                    state.pendingInput = nil
                } label: {
                    Image(.smallRemove)
                        .renderingMode(.template)
                }
                .buttonStyle(DarkerButtonStyle())
            }

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
        }
        .foregroundStyle(.gray200)
    }
}

#if DEBUG
    #Preview {
        InputButtons(inputExpanded: .constant(true), input: .sample)
    }
#endif

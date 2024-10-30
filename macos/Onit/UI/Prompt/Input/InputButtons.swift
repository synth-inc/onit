//
//  InputButtons.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import SwiftUI

struct InputButtons: View {
    @Environment(\.model) var model

    var body: some View {
        @Bindable var model = model

        Group {
            Button {
                model.input = nil
            } label: {
                Image(.smallRemove)
                    .renderingMode(.template)
            }
            .buttonStyle(DarkerButtonStyle())
            
            Button {
                model.inputExpanded.toggle()
            } label: {
                Color.clear
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(.smallChevRight)
                            .renderingMode(.template)
                            .rotationEffect(model.inputExpanded ? .degrees(90) : .zero)
                    }
            }
        }
        .foregroundStyle(.gray200)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        InputButtons()
    }
}
#endif

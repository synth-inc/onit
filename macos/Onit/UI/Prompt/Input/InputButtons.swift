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
        Button {
            @Bindable var model = model
            model.input = nil
        } label: {
            Image(.smallRemove)
                .renderingMode(.template)
        }
        .foregroundStyle(.gray200)
        .buttonStyle(DarkerButtonStyle())
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        InputButtons()
    }
}
#endif

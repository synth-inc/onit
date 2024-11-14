//
//  InputView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputView: View {
    @Environment(\.model) var model

    var input: Input

    var body: some View {
        VStack(spacing: 0) {
            InputTitle()
            divider
            InputBody(text: model.selectedText ?? "")
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray800)
                .strokeBorder(.gray600)
        }
        .padding([.horizontal, .top], 8)
    }

    var divider: some View {
        Color.gray600
            .frame(height: 1)
            .opacity(model.inputExpanded ? 1 : 0)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        InputView(input: .sample)
    }
}
#endif

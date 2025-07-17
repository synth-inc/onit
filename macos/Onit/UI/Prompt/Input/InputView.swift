//
//  InputView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Defaults
import SwiftUI

struct InputView: View {
    @Default(.showHighlightedTextInput) var showHighlightedTextInput

    var input: Input
    var isEditing: Bool = true

    var body: some View {
        if showHighlightedTextInput {
            VStack(spacing: 0) {
                InputTitle(input: input)
                divider
                InputBody(input: input)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray800)
                    .strokeBorder(.gray600)
            }
            .padding([.horizontal, .top], isEditing ? 12 : 0)
        }
    }

    var divider: some View {
        Color.gray600
            .frame(height: 1)
    }
}

#if DEBUG
    #Preview {
        InputView(input: .sample)
    }
#endif

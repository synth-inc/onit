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

    @State var inputExpanded: Bool = true

    var input: Input
    var isEditing: Bool = true

    var body: some View {
        if showHighlightedTextInput {
            VStack(spacing: 0) {
                InputTitle(inputExpanded: $inputExpanded, input: input)
                divider
                InputBody(inputExpanded: $inputExpanded, input: input)
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
            .opacity(inputExpanded ? 1 : 0)
    }
}

#if DEBUG
    #Preview {
        InputView(input: .sample)
    }
#endif

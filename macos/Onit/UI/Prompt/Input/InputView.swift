//
//  InputView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Defaults
import SwiftUI

struct InputView: View {
    var input: Input
    var isEditing: Bool = true
    
    @State var inputExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            InputTitle(inputExpanded: $inputExpanded, input: input, isEditing: isEditing)
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

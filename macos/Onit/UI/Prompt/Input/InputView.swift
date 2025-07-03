//
//  InputView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputView: View {

    @State var inputExpanded: Bool = true

    var input: Input
    var isEditing: Bool = true
    var close: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            InputTitle(
                inputExpanded: $inputExpanded,
                input: input,
                close: close
            )
            
            divider
            
            InputBody(
                inputExpanded: $inputExpanded,
                input: input
            )
        }
        .background(.gray500)
        .addBorder(
            cornerRadius: 6,
            stroke: .gray400
        )
        .padding([.horizontal, .top], isEditing ? 12 : 0)
    }

    var divider: some View {
        Color.gray400
            .frame(height: 1)
            .opacity(inputExpanded ? 1 : 0)
    }
}

#if DEBUG
    #Preview {
        InputView(input: .sample)
    }
#endif

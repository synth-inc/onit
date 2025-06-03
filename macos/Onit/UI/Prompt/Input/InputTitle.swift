//
//  InputTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputTitle: View {
    @Binding var inputExpanded: Bool
    var input: Input
    var close: (() -> Void)? = nil

    var title: String {
        guard let sourceText = input.application else { return "No Title" }
        return "From \(sourceText)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .styleText(
                    size: 12,
                    color: .gray100
                )
            
            Spacer()
            
            InputButtons(
                inputExpanded: $inputExpanded,
                input: input,
                close: close
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview {
    InputTitle(inputExpanded: .constant(true), input: .sample)
}

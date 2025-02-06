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

    var sourceString: String {
        guard let sourceText = input.application else { return "" }
        return " - \(sourceText)"
    }

    var inputString: String {
        "Input\(sourceString)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(inputString)
                .appFont(.medium13)
            Spacer()
            InputButtons(inputExpanded: $inputExpanded, input: input)
        }
        .foregroundStyle(.gray100)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    InputTitle(inputExpanded: .constant(true), input: .sample)
}

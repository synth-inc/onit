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
    var isEditing: Bool

    var sourceString: String {
        guard let sourceText = input.application else { return "" }
        return " [\(sourceText)]"
    }

    var inputString: String {
        "From\(sourceString)"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(inputString)
                .appFont(.medium12)
                .textSelection(.enabled)
            Spacer()
            InputButtons(inputExpanded: $inputExpanded, input: input, isEditing: isEditing)
        }
        .foregroundStyle(.gray100)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview {
    InputTitle(inputExpanded: .constant(true), input: .sample, isEditing: true)
}

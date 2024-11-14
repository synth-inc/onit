//
//  InputTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputTitle: View {
    @Environment(\.model) var model
//    var source: String?

    var sourceString: String {
        guard let sourceText = model.sourceText else { return "" }
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
            InputButtons()
        }
        .foregroundStyle(.gray100)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    InputTitle()
}

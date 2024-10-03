//
//  InputTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputTitle: View {
    var source: String?

    var sourceString: String {
        guard let source else { return "" }
        return " - \(source)"
    }

    var inputString: String {
        "Input\(sourceString)"
    }

    var body: some View {
        HStack {
            Text(inputString)
                .appFont(.medium13)
            Spacer()
        }
        .foregroundStyle(.gray100)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    InputTitle(source: "Xcode")
}

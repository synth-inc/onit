//
//  InputBody.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputBody: View {
    var text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .appFont(.medium16)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    InputBody(text: "This is a long sample string")
}

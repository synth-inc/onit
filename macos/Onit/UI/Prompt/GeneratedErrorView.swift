//
//  GeneratedErrorView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import SwiftUI

struct GeneratedErrorView: View {
    var errorDescription: String

    var body: some View {
        HStack(spacing: 8) {
            Image(.warning)
            ScrollView {
                Text(errorDescription)
                    .appFont(.medium14)
                    .foregroundStyle(.warning)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
        .padding(.top, 6)
    }
}

#Preview {
    GeneratedErrorView(errorDescription: "Message")
}

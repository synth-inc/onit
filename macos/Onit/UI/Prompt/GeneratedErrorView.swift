//
//  GeneratedErrorView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import SwiftUI

struct GeneratedErrorView: View {
    var error: Error

    var body: some View {
        HStack(spacing: 8) {
            Image(.warning)
            ScrollView {
                Text(error.localizedDescription)
                    .appFont(.medium14)
                    .foregroundStyle(.warning)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .padding(.top, 6)
    }
}

#Preview {
    GeneratedErrorView(error: .sample("Message"))
}

//
//  ContextMenuLoading.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuLoading: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            shimmer
            shimmer
            shimmer
        }
        .padding([.horizontal, .bottom], 8)
    }
}

// MARK: - Child Components

extension ContextMenuLoading {
    private var shimmer: some View {
        Shimmer(
            width: .infinity,
            height: ButtonConstants.textButtonHeight,
            cornerRadius: 8
        )
    }
}

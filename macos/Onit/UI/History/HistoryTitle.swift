//
//  HistoryTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryTitle: View {
    @Environment(\.windowState) private var state

    var body: some View {
        // Only show content if windowState is available
        if let state = state {
            HStack {
                Text("History")
                    .appFont(.medium14)
                    .foregroundStyle(.FG)
                Spacer()
                Button {
                    state.showHistory = false
                } label: {
                    Image(.smallCross)
                        .renderingMode(.template)
                        .foregroundStyle(.gray200)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            Text("History")
                .appFont(.medium16)
                .foregroundStyle(.white)
        }
    }
}

#if DEBUG
    #Preview {
        HistoryTitle()
    }
#endif

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
        HStack {
            Text("History")
                .appFont(.medium14)
                .foregroundStyle(Color.S_0)
            Spacer()
            Button {
                state?.showHistory = false
            } label: {
                Image(.smallCross)
                    .renderingMode(.template)
                    .foregroundStyle(Color.S_2)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#if DEBUG
    #Preview {
        HistoryTitle()
    }
#endif

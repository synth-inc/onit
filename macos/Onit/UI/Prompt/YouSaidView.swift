//
//  YouSaidView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct YouSaidView: View {
    @Environment(\.model) var model

    @State var appeared = false

    var body: some View {
        if let text = model.youSaid {
            Text(text)
                .appFont(.medium14)
                .foregroundStyle(.FG)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(.gray800, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.gray500)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
//                .padding(.horizontal, appeared ? 16 : 0)
                .onAppear {
                    withAnimation(.bouncy(duration: 1/4)) {
                        appeared = true
                    }
                }
                .onDisappear {
                    withAnimation(.bouncy(duration: 0)) {
                        appeared = false
                    }
                }
        }
    }
}

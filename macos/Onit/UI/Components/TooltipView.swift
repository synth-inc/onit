//
//  TooltipView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/30/24.
//

import SwiftUI

struct TooltipView: View {
    var tooltip: Tooltip

    var body: some View {
        HStack(spacing: 0) {
            Text(tooltip.prompt)
                .appFont(.medium12)
                .padding(.vertical, 8)

            Group {
                switch tooltip.shortcut {
                case .keyboard(let shortcut):
                    KeyboardShortcutView(shortcut: shortcut)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(.gray400, in: .rect(cornerRadius: 6))
                        .padding(4)
                        .fixedSize()
                case .text(let text):
                    Text(text)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(.gray400, in: .rect(cornerRadius: 6))
                        .padding(4)
                        .fixedSize()
                case .none:
                    Spacer()
                        .frame(width: 8)
                }
            }
            .appFont(.medium10)
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .background {
            tooltipBackground
        }
        .frame(minHeight: 78)
    }

    var tooltipBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray500)
//            .shadow(color: .black.opacity(0.36), radius: 2.5, x: 0, y: 0)
    }
}

#Preview {
    TooltipView(tooltip: .sample)
}
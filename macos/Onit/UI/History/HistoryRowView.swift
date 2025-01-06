//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.model) var model

    var prompt: Prompt

    var body: some View {
        Button {
            model.prompt = prompt
            model.instructions = prompt.text
            model.generationIndex = prompt.responses.count - 1
            model.showHistory = false
        } label: {
            HStack {
                Text(prompt.text)
                    .appFont(.medium16)
                    .foregroundStyle(.FG)
                Spacer()
                Text("\(prompt.responses.count)")
                    .appFont(.medium13)
                    .monospacedDigit()
                    .foregroundStyle(.gray200)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .buttonStyle(HoverableButtonStyle(background: true))
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        HistoryRowView(prompt: .sample)
    }
}
#endif

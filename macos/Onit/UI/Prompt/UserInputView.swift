//
//  UserInputView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct UserInputView: View {
    @Environment(\.model) var model

    let prompt: Prompt
    let isSent: Bool

    var body: some View {
        VStack(spacing: 0) {
            ContextList(contextList: prompt.contextList, isSent: isSent)
            Text(prompt.instruction)
                .appFont(.medium14)
                .foregroundStyle(.FG)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.gray800, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.gray500)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

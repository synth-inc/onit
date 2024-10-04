//
//  OmniPromptView.swift
//  Omni
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct OnitPromptView: View {
    let shortcut = KeyboardShortcut("o", modifiers: [.option, .command])

    var body: some View {
        HStack(spacing: 3) {
            Image(.smirkIcon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 14, height: 14)
            KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                .font(.system(size: 13, weight: .light))
        }
        .foregroundStyle(Color.secondary)
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.thickMaterial)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    OnitPromptView()
}

//
//  StopGenerationButton.swift
//  Onit
//
//  Created by OpenAI on 2023-11-20.
//

import SwiftUI
import Defaults

struct StopGenerationButton: View {
    @Environment(\.windowState) private var state

    private let shortcut = KeyboardShortcut(.delete, modifiers: [.command])

    var body: some View {
        TextButton(
            gap: 4,
            height: ToolbarButtonStyle.height,
            fillContainer: false,
            horizontalPadding: 8,
            cornerRadius: ToolbarButtonStyle.cornerRadius,
            background: .gray800,
            hoverBackground: .gray600,
            fontSize: 13,
            fontColor: .gray200,
            text: "Stop",
            child: { KeyboardShortcutView(shortcut: shortcut) },
            action: { state.stopGeneration() }
        )
        .keyboardShortcut(shortcut)
    }
}

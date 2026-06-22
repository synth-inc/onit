//
//  CopyButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftUI

struct CopyButton: View {
    @State var showCheckmark = false

    var text: String
    var stripMarkdown = false
    var iconSize: CGFloat = 18
    var buttonSize: CGFloat = ToolbarButtonStyle.height
    var inactiveColor: Color = Color.S_0
    var cornerRadius: CGFloat = ToolbarButtonStyle.cornerRadius

    private var textToCopy: String {
        stripMarkdown ? text.stripMarkdown() : text
    }

    var body: some View {
        IconButton(
            icon: .copy,
            iconSize: iconSize,
            buttonSize: buttonSize,
            inactiveColor: inactiveColor,
            cornerRadius: cornerRadius,
            tooltipPrompt: String.localized("Copy", table: "Sidekick")
        ) {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(textToCopy, forType: .string)
            showCheckmark = true

            Task { @MainActor in
                try await Task.sleep(for: .seconds(2))
                showCheckmark = false
            }
        }
        .opacity(showCheckmark ? 0 : 1)
        .overlay {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.lime400)
                .opacity(showCheckmark ? 1 : 0)
        }
        .addAnimation(dependency: showCheckmark)
    }
}

#Preview {
    CopyButton(text: "Hello world")
}

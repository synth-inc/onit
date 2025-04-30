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

    private var textToCopy: String {
        stripMarkdown ? text.stripMarkdown() : text
    }

    var body: some View {
        IconButton(
            icon: .copy,
            iconSize: 18,
            action: {
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString(textToCopy, forType: .string)
                showCheckmark = true

                Task { @MainActor in
                    try await Task.sleep(for: .seconds(2))
                    showCheckmark = false
                }
            },
            tooltipPrompt: "Copy"
        )
        .opacity(showCheckmark ? 0 : 1)
        .overlay {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.limeGreen)
                .opacity(showCheckmark ? 1 : 0)
        }
        .addAnimation(dependency: showCheckmark)
    }
}

#Preview {
    CopyButton(text: "Hello world")
}

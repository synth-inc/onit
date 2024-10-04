//
//  KeyboardShortcutView.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct KeyboardShortcutView: View {
    var shortcut: KeyboardShortcut
    var characterWidth: CGFloat = 11
    var spacing: CGFloat = 3

    var body: some View {
        HStack(spacing: spacing) {
            modifiers
            key
        }
    }

    var modifiers: some View {
        ForEach(shortcut.modifiers.array) { modifier in
            ModifierView(modifier: modifier)
                .frame(width: characterWidth, height: characterWidth)
        }
    }

    var key: some View {
        KeyView(key: shortcut.key)
            .frame(width: characterWidth, height: characterWidth)
    }

    struct KeyView: View {
        var key: KeyEquivalent

        var body: some View {
            switch key {
            case .return:
                Text("⏎")
            case .delete:
                Text("⌫")
            case .space:
                Text("␣")
            default:
                Text(String(key.character).uppercased())
            }
        }
    }

    struct ModifierView: View {
        var modifier: EventModifiers

        var body: some View {
            switch modifier {
            case .command:
                Text("⌘")
            case .option:
                Text("⌥")
            case .shift:
                Text("⇧")
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    KeyboardShortcutView(shortcut: .init("k", modifiers: [.command, .option]))
}

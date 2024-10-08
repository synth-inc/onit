//
//  MenuSettings.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuSettings: View {
    var shortcut: KeyboardShortcut {
        KeyboardShortcut(",")
    }

    var body: some View {
        MenuBarRow(.settings) {
            Text("Settings...")
                .padding(.horizontal, 10)
        } trailing: {
            KeyboardShortcutView(shortcut: shortcut)
                .padding(.horizontal, 10)
        }
        .keyboardShortcut(",")
    }
}

#Preview {
    MenuSettings()
}

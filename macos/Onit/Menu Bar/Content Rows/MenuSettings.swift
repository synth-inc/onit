//
//  MenuSettings.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuSettings: View {
    @Environment(\.openSettings) var openSettings

    var shortcut: KeyboardShortcut {
        KeyboardShortcut(",")
    }

    var body: some View {
        MenuBarRow {
            openSettings()
        } leading: {
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

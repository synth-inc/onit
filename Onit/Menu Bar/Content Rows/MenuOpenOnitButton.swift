//
//  OpenOnitButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuOpenOnitButton: View {
    @Environment(\.openWindow) var openWindow

    var shortcut: KeyboardShortcut {
        .init(.space, modifiers: [.option, .command])
    }

    var body: some View {
        MenuBarRow {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        } leading: {
            HStack(spacing: 4) {
                Image(.smirkIcon)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.black)
                    .scaledToFit()
                    .padding(1)
                    .frame(width: 16, height: 16)
                Text("Open Onit")
            }
            .padding(.leading, 5)
        } trailing: {
            KeyboardShortcutView(shortcut: shortcut)
                .padding(.trailing, 10)
        }
//        .keyboardShortcut(.space, modifiers: [.command, .option])
    }
}

#Preview {
    MenuOpenOnitButton()
}

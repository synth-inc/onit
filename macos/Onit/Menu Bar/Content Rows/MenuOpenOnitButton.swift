//
//  OpenOnitButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuOpenOnitButton: View {
    @Environment(\.model) var model

    var shortcut: KeyboardShortcut {
        .init(.space, modifiers: [.option, .command])
    }

    var body: some View {
        MenuBarRow {
            model.showPanel()
        } leading: {
            HStack(spacing: 4) {
                Image(.smirk)
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
    }
}

#Preview {
    MenuOpenOnitButton()
        .environment(Model())
}
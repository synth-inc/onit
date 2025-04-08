//
//  OpenOnitButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import KeyboardShortcuts

struct MenuOpenOnitButton: View {
    
    var shortcut: KeyboardShortcut {
        .init(.space, modifiers: [.option, .command])
    }

    var body: some View {
        MenuBarRow {
            OnitPanelManager.shared.state.launchPanel()
        } leading: {
            HStack(spacing: 4) {
                Image(.smirk)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.primary)
                    .scaledToFit()
                    .padding(1)
                    .frame(width: 16, height: 16)
                Text("Open Onit")
            }
            .padding(.leading, 5)
        } trailing: {
            KeyboardShortcutView(
                shortcut: KeyboardShortcuts.getShortcut(
                    for: .launchWithAutoContext)?.native
            )
            .foregroundStyle(.gray200)
            .appFont(.medium13)
        }
    }
}

#if DEBUG
    #Preview {
        MenuOpenOnitButton()
    }
#endif

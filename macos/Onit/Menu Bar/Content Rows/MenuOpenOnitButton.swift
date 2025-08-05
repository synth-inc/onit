//
//  OpenOnitButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import KeyboardShortcuts

struct MenuOpenOnitButton: View {
    var body: some View {
        MenuBarRow {
            PanelStateCoordinator.shared.launchPanel()
        } leading: {
            HStack(spacing: 4) {
                Image(.noodle)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.S_0)
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
            .foregroundStyle(Color.S_2)
            .appFont(.medium13)
        }
    }
}

#if DEBUG
    #Preview {
        MenuOpenOnitButton()
    }
#endif

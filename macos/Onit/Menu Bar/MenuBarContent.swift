//
//  MenuBarLabel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import Defaults

struct MenuBarContent: View {
    var body: some View {
        VStack(spacing: 5) {
            MenuVersion()
            MenuDivider()
            MenuCheckForPermissions()
            MenuOpenOnitButton()
            MenuHideTimerStatus()
            MenuDivider()
            MenuSettings()
            MenuCheckForUpdates()
            MenuJoinDiscord()
            MenuDivider()
            MenuQuit()
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
    }
}

#Preview {
    MenuBarContent()
}

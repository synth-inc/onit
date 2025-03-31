//
//  MenuSettings.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import KeyboardShortcuts
import SwiftUI

struct MenuSettings: View {
    @Environment(\.openSettings) var openSettings
    @Environment(\.model) var model

    var body: some View {
        MenuBarRow {
            NSApp.activate()
            if NSApp.isActive {
                model.setSettingsTab(tab: .general)
                openSettings()
            }
        } leading: {
            Text("Settings...")
                .padding(.horizontal, 10)
        }
    }
}

#Preview {
    MenuSettings()
}

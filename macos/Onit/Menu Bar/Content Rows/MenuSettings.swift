//
//  MenuSettings.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import KeyboardShortcuts

struct MenuSettings: View {
    @Environment(\.openSettings) var openSettings
    @Environment(\.model) var model
    
    var body: some View {
        MenuBarRow {
            NSApp.activate()
            if NSApp.isActive {
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

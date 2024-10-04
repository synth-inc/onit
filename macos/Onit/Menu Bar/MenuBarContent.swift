//
//  MenuBarLabel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarContent: View {
    var body: some View {
        VStack(spacing: 5) {
            MenuOpenOnitButton()
            MenuDivider()
            MenuAppearsInPicker()
            MenuDivider()
            MenuSettings()
            MenuHowItWorks()
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

//
//  MenuBarScene.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarScene: Scene {
    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
        } label: {
            label
        }
        .menuBarExtraStyle(.window)
    }

    var label: some View {
        Image(.smirk)
            .renderingMode(.template)
            .foregroundStyle(.white)
    }
}

//
//  MenuBarScene.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarScene: Scene {
    @Environment(\.model) var model

    var body: some Scene {
        @Bindable var model = model

        MenuBarExtra {
            MenuBarContent()
        } label: {
            Image(.smirk)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $model.showMenuBarExtra)
        .commands { }
    }

    var label: some View {
        Image(.smirk)
            .renderingMode(.template)
            .foregroundStyle(.white)
    }
}

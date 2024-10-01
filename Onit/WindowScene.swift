//
//  WindowScene.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct WindowScene: Scene {
    var body: some Scene {
        Window("Onit", id: .main) {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 84)
        .handlesExternalEvents(matching: [.launch])
    }
}

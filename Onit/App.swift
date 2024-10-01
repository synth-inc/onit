//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI
import KeyboardShortcuts

@main
struct App: SwiftUI.App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow

    init() {
//        KeyboardShortcuts.launch()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
        } label: {
            Image(.smirkIcon)
                .renderingMode(.template)
                .foregroundStyle(.white)
        }
        .menuBarExtraStyle(.window)

        Window("Onit", id: .main) {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)
        .defaultSize(width: 400, height: 84)
        .defaultWindowPlacement { layoutRoot, context in
            let padding: CGFloat = 0
            let visibleRect = context.defaultDisplay.visibleRect
            let x = visibleRect.minX + padding
            let y = visibleRect.minY + padding
            return WindowPlacement(x: 0, y: 0)
        }
        .keyboardShortcut(.space, modifiers: [.control, .option, .command])
        .handlesExternalEvents(matching: .main)
    }
}

//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI
import KeyboardShortcuts
import MenuBarExtraAccess

@main
struct App: SwiftUI.App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow

    init() {
        KeyboardShortcuts.launch()
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

        WindowScene()
            .commands {
                CommandGroup(after: .appInfo) {
                    Color.clear
                        .onAppear {
                            openWindow(id: .main)
                        }
                }
            }
    }
}

//@main
struct TestApp: SwiftUI.App {
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        MenuBarExtra {
            Button("First") {
                openWindow(id: "Fourth")
            }
        } label: {
            Text("Second")
        }

        Window("Third", id: "Fourth") {
            Text("Fifth")
                .onAppear {
                    for window in NSApplication.shared.windows {
                        window.level = .floating
                    }
                }
        }
    }
}

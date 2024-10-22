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
    @Environment(\.model) var model

    init() {

        KeyboardShortcuts.onKeyUp(for: .launch) { [weak model] in
            model?.togglePanel()
        }
        model.showPanel()

        #if !targetEnvironment(simulator)
        Accessibility.requestPermissions()
        Accessibility.setupWindow(withView: OnitPromptView())
        Accessibility.observeActiveApplication()
        #endif

    }

    var body: some Scene {
        @Bindable var model = model

        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuIcon()
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $model.showMenuBarExtra)
        .commands { }

        Settings {
            Form {
                KeyboardShortcuts.Recorder("Launch Onit", name: .launch) { _ in
                    Accessibility.resetPrompt(with: OnitPromptView().environment(model))
                }
                .padding()
            }
            .frame(minWidth: 400, minHeight: 200)
        }
    }
}

// MARK: - Testing

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

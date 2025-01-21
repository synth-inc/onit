//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI
import KeyboardShortcuts
import MenuBarExtraAccess
import FirebaseCore
import Foundation

@main
struct App: SwiftUI.App {
    @Environment(\.model) var model
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {

        KeyboardShortcuts.onKeyUp(for: .launch) { [weak model] in
            model?.launchShortcutAction()
        }
        KeyboardShortcuts.onKeyUp(for: .toggleLocalMode) { [weak model] in
            model?.toggleLocalVsRemoteShortcutAction()
        }
        KeyboardShortcuts.onKeyUp(for: .newChat) { [weak model] in
            model?.newChat()
        }
        KeyboardShortcuts.onKeyUp(for: .resizeWindow) { [weak model] in
            model?.resizeWindow()
        }
        KeyboardShortcuts.onKeyUp(for: .toggleModels) { [weak model] in
            model?.toggleModelsPanel()
        }
        KeyboardShortcuts.onKeyUp(for: .escape) { [weak model] in
            model?.escapeAction()
        }

        model.showPanel()
        
        #if !targetEnvironment(simulator)
//        Accessibility.requestPermissions()
//        Accessibility.setModel(model)
//        Accessibility.setupWindow(withView: StaticPromptView())
//        Accessibility.observeActiveApplication()
//        Accessibility.observeSystemClicks()
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
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
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

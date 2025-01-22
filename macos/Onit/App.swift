//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI
import KeyboardShortcuts
import MenuBarExtraAccess
import Foundation
import SwiftyBeaver

let log = SwiftyBeaver.self

@main
struct App: SwiftUI.App {
    
    @Environment(\.model) var model
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        let console = ConsoleDestination()
        log.addDestination(console)
        
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

        showLoadingScreen()
        
        AccessibilityPermissionManager.shared.setModel(model)
        
        // TODO: KNA - Replace this
        #if !targetEnvironment(simulator)
        Accessibility.setModel(model)
        Accessibility.setupWindow(withView: StaticPromptView())
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
    
    @MainActor private func showLoadingScreen() {
        let loadingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        let loadingView = LoadingView(onLoadingFinished: {
            loadingWindow.close()
            model.showPanel()
        })
        
        let launchView = NSHostingController(rootView: loadingView)
        loadingWindow.contentViewController = launchView
        loadingWindow.title = "Loading"
        loadingWindow.center()
        loadingWindow.makeKeyAndOrderFront(nil)
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

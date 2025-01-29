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
import PostHog

@main
struct App: SwiftUI.App {
    
    @Environment(\.model) var model
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    @State var accessibilityPermissionRequested = false
    
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

        featureFlagsManager.configure()
        model.showPanel()
        

        #if !targetEnvironment(simulator)
        
        let hostingController = NSHostingController(rootView: StaticPromptView())
        let window = NSWindow(contentViewController: hostingController)
        
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        AccessibilityPermissionManager.shared.setModel(model)
        AccessibilityNotificationsManager.shared.setModel(model)
        AccessibilityNotificationsManager.shared.setupWindow(window)
        WindowHelper.shared.setupWindow(window)
        
        #endif
    }

    var body: some Scene {
        @Bindable var model = model

        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuIcon()
                .onChange(of: model.accessibilityPermissionStatus, initial: true) { oldValue, newValue in
                    switch newValue {
                    case .granted:
                        AccessibilityNotificationsManager.shared.start()
                        TapListener.shared.start()
                    case .denied:
                        AccessibilityNotificationsManager.shared.stop()
                        TapListener.shared.stop()
                    default:
                        break
                    }
                }
                .onChange(of: featureFlagsManager.flags.accessibility, initial: true) { oldValue, newValue in
                    if newValue {
                        if !accessibilityPermissionRequested {
                            accessibilityPermissionRequested = true
                            AccessibilityPermissionManager.shared.requestPermission()
                        }
                        AccessibilityPermissionManager.shared.startListeningPermission()
                    } else {
                        AccessibilityPermissionManager.shared.stopListeningPermission()
                    }
                }
                .onChange(of: model.showDebugWindow, initial: true) { oldValue, newValue in
                    if newValue {
                        model.openDebugWindow()
                    } else {
                        model.closeDebugWindow()
                    }
                }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $model.showMenuBarExtra)
        .commands { }

        Settings {
            SettingsView()
            .onAppear {
                if let window = NSApplication.shared.windows.first(where: { $0.contentViewController is NSHostingController<SettingsView> }) {
                    window.level = .floating
                }
            }
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

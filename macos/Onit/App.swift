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
import ServiceManagement

@main
struct App: SwiftUI.App {
    
    @Environment(\.model) var model
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    // @Default(.launchOnStartupRequested) var launchOnStartupRequested
    // TODO: KNA - Replace by future Defaults SDK
    @AppStorage("launchOnStartupRequested") var launchOnStartupRequested: Bool = false
    
    @State var accessibilityPermissionRequested = false
    
    init() {
        KeyboardShortcuts.onKeyUp(for: .launch) { [weak model] in
            let eventProperties: [String: Any] = [
                "app_hidden": model?.panel == nil,
                "highlight_hint_visible": HighlightHintWindowController.shared.isVisible(),
                "highlight_hint_mode": FeatureFlagManager.shared.highlightHintMode
            ]
            PostHogSDK.shared.capture("shortcut_launch", properties: eventProperties)
            
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
        KeyboardShortcuts.onKeyUp(for: .escape) { [weak model] in
            model?.escapeAction()
        }
        KeyboardShortcuts.onKeyUp(for: .launchWithAutoContext) { [weak model] in
            let eventProperties: [String: Any] = [
                "app_hidden": model?.panel == nil
            ]
            PostHogSDK.shared.capture("shortcut_launch_with_auto_context", properties: eventProperties)
            model?.addAutoContext()
            model?.launchPanel()
        }

        featureFlagsManager.configure()
        // For testing new user experience
        // model.clearTokens()
        model.showPanel()
        

        #if !targetEnvironment(simulator)
        
        AccessibilityPermissionManager.shared.setModel(model)
        AccessibilityNotificationsManager.shared.setModel(model)
        
        #endif
    }

    var body: some Scene {
        @Bindable var model = model

        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuIcon()
                .onAppear {
                    checkLaunchOnStartup()
                }
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
                .onChange(of: featureFlagsManager.accessibility, initial: true) { oldValue, newValue in
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
    
    private func checkLaunchOnStartup() {
        if !launchOnStartupRequested {
            do {
                try SMAppService.mainApp.register()
                launchOnStartupRequested = true
            } catch {
                print("Error: \(error)")
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

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

        FeatureFlagManager.shared.configure()
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
    
    let featureFlagsReceivedPub = NotificationCenter.default.publisher(for: PostHogSDK.didReceiveFeatureFlags)

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
                .onReceive(featureFlagsReceivedPub) { _ in featureFlagsReceived() }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $model.showMenuBarExtra)
        .commands { }

        Settings {
            SettingsView()
        }
    }
    
    /**
     * On feature flags received event :
     * - Initialize stuff depending on feature flag
     * - Notify the app that the loading is finished
     */
    private func featureFlagsReceived() {
        if FeatureFlagManager.shared.isAccessibilityEnabled() {
            #if !targetEnvironment(simulator)
            
            AccessibilityPermissionManager.shared.requestPermission()
            
            #endif
        }
        
        // TODO: KNA - Refresh UI ?
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

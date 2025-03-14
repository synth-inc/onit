//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import Foundation
import KeyboardShortcuts
import MenuBarExtraAccess
import PostHog
import ServiceManagement
import SwiftUI

@main
struct App: SwiftUI.App {
    @Environment(\.model) var model
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    @Default(.isRegularApp) var isRegularApp
    @Default(.launchOnStartupRequested) var launchOnStartupRequested

    @State var accessibilityPermissionRequested = false
    
    private var frontmostApplicationOnLaunch: NSRunningApplication?

    init() {
        frontmostApplicationOnLaunch = NSWorkspace.shared.frontmostApplication
        
        KeyboardShortcutsManager.configure(model: model)
        featureFlagsManager.configure()
        
        // For testing new user experience
        // clearTokens()
        model.showPanel()

        #if !targetEnvironment(simulator)
        AccessibilityPermissionManager.shared.setModel(model)
        AccessibilityNotificationsManager.shared.setModel(model)

        SplitViewManager.shared.configure(model: model)
        SplitViewManager.shared.startObserving()
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
                    toggleUIElementMode(enable: isRegularApp)
                }
                .onChange(of: model.accessibilityPermissionStatus, initial: true) {
                    _, newValue in
                    AccessibilityAnalytics.logPermission(local: newValue)
                    
                    switch newValue {
                    case .granted:
                        AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationOnLaunch?.processIdentifier)
                        TapListener.shared.start()
                    case .denied:
                        AccessibilityNotificationsManager.shared.stop()
                        TapListener.shared.stop()
                    default:
                        break
                    }
                }
                .onChange(of: featureFlagsManager.accessibility, initial: true) {
                    _, newValue in
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
                .onChange(of: [
                    featureFlagsManager.accessibility,
                    featureFlagsManager.accessibilityInput,
                    featureFlagsManager.accessibilityAutoContext
                ], initial: true) { oldValue, newValue in
                    AccessibilityAnalytics.logFlags()
                }
                .onChange(of: model.showDebugWindow, initial: true) { oldValue, newValue in
                    if newValue {
                        model.openDebugWindow()
                    } else {
                        model.closeDebugWindow()
                    }
                }
                .onChange(of: isRegularApp) { _, newValue in
                    toggleUIElementMode(enable: newValue)
                }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $model.showMenuBarExtra)
        .commands {}

        Settings {
            SettingsView()
                .modelContainer(model.container)
                .onAppear {
                    if let window = NSApplication.shared.windows.first(where: {
                        $0.contentViewController is NSHostingController<SettingsView>
                    }) {
                        window.level = .floating
                    }
                }
        }
    }

    private func clearTokens() {
        // Helpful for debugging the new-user-experience
        let defaultsKeys: [Defaults._AnyKey] = [
            .openAIToken, .anthropicToken, .xAIToken, .googleAIToken,
            .isOpenAITokenValidated, .isAnthropicTokenValidated, .isXAITokenValidated,
            .isGoogleAITokenValidated,
            .useOpenAI, .useAnthropic, .useXAI, .useGoogleAI, .useLocal,
        ]

        Defaults.reset(defaultsKeys)
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
    
    private func toggleUIElementMode(enable: Bool) {
        if enable {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
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

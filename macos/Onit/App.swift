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
    @Environment(\.appState) var appState
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var debugManager = DebugManager.shared
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    @Default(.isRegularApp) var isRegularApp
    @Default(.launchOnStartupRequested) var launchOnStartupRequested

    @State var accessibilityPermissionRequested = false
    
    private var frontmostApplicationOnLaunch: NSRunningApplication?

    init() {
        frontmostApplicationOnLaunch = NSWorkspace.shared.frontmostApplication
        
        KeyboardShortcutsManager.configure()
        featureFlagsManager.configure()
        
        // For testing new user experience
        // clearTokens()
        
        if !isRegularApp {
            TetherAppsManager.shared.state.launchPanel()
        }
    }

    var body: some Scene {
        @Bindable var appState = appState

        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuIcon()
                .onAppear {
                    checkLaunchOnStartup()
                    toggleUIElementMode(enable: isRegularApp)
                }
                .onChange(of: accessibilityPermissionManager.accessibilityPermissionStatus, initial: true) {
                    _, newValue in
                    AccessibilityAnalytics.logPermission(local: newValue)
                    
                    switch newValue {
                    case .granted:
                        AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationOnLaunch?.processIdentifier)
                        TetherAppsManager.shared.startObserving()
                        TapListener.shared.start()
                    case .denied:
                        AccessibilityNotificationsManager.shared.stop()
                        TetherAppsManager.shared.stopObserving()
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
                .onChange(of: debugManager.showDebugWindow, initial: true) { oldValue, newValue in
                    if newValue {
                        debugManager.openDebugWindow()
                    } else {
                        debugManager.closeDebugWindow()
                    }
                }
                .onChange(of: isRegularApp) { _, newValue in
                    toggleUIElementMode(enable: newValue)
                }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $appState.showMenuBarExtra)
        .commands {}

        Settings {
            SettingsView()
                .modelContainer(SwiftDataContainer.appContainer)
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

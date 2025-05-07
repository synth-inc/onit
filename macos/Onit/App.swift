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
import SwiftyBeaver

let log = SwiftyBeaver.self

@main
struct App: SwiftUI.App {
    @Environment(\.appState) var appState
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var debugManager = DebugManager.shared
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    @Default(.isRegularApp) var isRegularApp
    @Default(.launchOnStartupRequested) var launchOnStartupRequested

    @Default(.autoContextEnabled) var autoContextEnabled
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    
    @State var accessibilityPermissionRequested = false
    @State private var frontmostApplicationOnLaunch: NSRunningApplication?

    init() {
        configureSwiftBeaver()
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
                        TetherAppsManager.shared.startObserving()
                        AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationOnLaunch?.processIdentifier)
                        UntetheredScreenManager.shared.stopObserving()
                        frontmostApplicationOnLaunch = nil
                    case .denied, .notDetermined:
                        TetherAppsManager.shared.stopObserving()
                        AccessibilityNotificationsManager.shared.stop()
                        UntetheredScreenManager.shared.startObserving()
                    }
                }
                .onChange(of: Defaults[.autoContextEnabled], initial: true) {
                    _, newValue in
                    if newValue {
                        AccessibilityPermissionManager.shared.startListeningPermission()
                    } else {
                        AccessibilityPermissionManager.shared.stopListeningPermission()
                    }
                }
                .onChange(of: [
                    autoContextEnabled,
                    autoContextFromCurrentWindow,
                    autoContextFromHighlights
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
                .background( WindowAccessor { window in
                    let floatingLevel: NSWindow.Level = .floating
                    let settingsWindowLevel: NSWindow.Level = NSWindow.Level(rawValue: floatingLevel.rawValue + 1)
                    window.level = settingsWindowLevel
                })
        }
    }
    
    private func configureSwiftBeaver() {
        let fileManager = FileManager.default
        let logsDirectory = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Onit", isDirectory: true)
        let logFileURL = logsDirectory.appendingPathComponent("Onit.log")
        do {
            if !fileManager.fileExists(atPath: logsDirectory.path) {
                try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("Failed to create log directory: \(error)")
        }
        let file = FileDestination(logFileURL: logFileURL)
        let console = ConsoleDestination()
        
        log.addDestination(console)
        log.addDestination(file)
//        #endif
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

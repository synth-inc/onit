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

    @Default(.launchOnStartupRequested) var launchOnStartupRequested
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    
    @State var accessibilityPermissionRequested = false
    @State private var frontmostApplicationOnLaunch: NSRunningApplication?

    init() {
        configureSwiftBeaver()
        frontmostApplicationOnLaunch = NSWorkspace.shared.frontmostApplication
        
        accessibilityPermissionManager.configure()
        
        KeyboardShortcutsManager.configure()
        featureFlagsManager.configure()
        
        // For testing new user experience
        // clearTokens()
    }

    var body: some Scene {
        @Bindable var appState = appState

        MenuBarExtra {
            MenuBarContent()
        } label: {
            MenuIcon()
                .onAppear {
                    checkLaunchOnStartup()
                    restoreSession()
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
                .onChange(of: [
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

        Window("URLHandler", id: "urlHandler") {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    if let window = NSApp.windows.first(where: { $0.title == "URLHandler" }) {
                        window.setFrame(NSRect(x: 0, y: 0, width: 1, height: 1), display: false)
                        window.isOpaque = false
                        window.hasShadow = false
                        window.backgroundColor = .clear
                        window.isReleasedWhenClosed = false
                        window.level = .floating
                        window.ignoresMouseEvents = true
                        window.styleMask = []
                        window.orderOut(nil)
                    }
                }
                .onOpenURL { url in
                    appState.handleTokenLogin(url)
                }
        }
    }
    
    private func configureSwiftBeaver() {
        #if DEBUG
        let logFileURL = URL(fileURLWithPath: "/tmp/Onit.log")
        
        let file = FileDestination(logFileURL: logFileURL)
        let console = ConsoleDestination()
        
        log.addDestination(console)
        log.addDestination(file)
        #endif
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

    private func restoreSession() {
        if TokenManager.token != nil && appState.account == nil {
            Task {
                let client = FetchingClient()
                appState.account = try? await client.getAccount()
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

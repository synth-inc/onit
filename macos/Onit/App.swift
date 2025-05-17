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
    @Environment(\.dismissWindow) private var dismissWindow
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var debugManager = DebugManager.shared

    @Default(.launchOnStartupRequested) var launchOnStartupRequested
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    @Default(.authFlowStatus) var authFlowStatus
    
    private let appCoordinator: AppCoordinator

    init() {
        // Always configure SwiftBeaver first to have logger working in initializers
        Self.configureSwiftBeaver()
        
        let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        appCoordinator = AppCoordinator(frontmostPidAtLaunch: pid)
        
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
        
        Window("Create an Account or Log In",id: windowOnboardingAuthId) {
            if authFlowStatus != .hideAuth && appState.account == nil {
                VStack {
                    AuthFlow()
                }
                .background(Color.black)
                .frame(width: 400, height: 800)
                .addBorder(
                    cornerRadius: 14,
                    lineWidth: 2,
                    stroke: .gray600
                )
                .edgesIgnoringSafeArea(.top)
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .onChange(of: appState.account) { _, new in
            if new != nil {
                dismissWindow(id: windowOnboardingAuthId)
            }
        }
        .onChange(of: authFlowStatus) { _, new in
            if new == .hideAuth {
                dismissWindow(id: windowOnboardingAuthId)
            }
        }
    }
    
    private static func configureSwiftBeaver() {
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

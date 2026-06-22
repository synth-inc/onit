//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import Foundation
import KeyboardShortcuts
import PostHog
import SwiftUI
import SwiftyBeaver

let log = SwiftyBeaver.self

@main
struct App: SwiftUI.App {
    @Environment(\.appState) var appState
    @Environment(\.dismissWindow) private var dismissWindow
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var debugManager = DebugManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @Default(.launchOnStartupRequested) var launchOnStartupRequested
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    @Default(.autoContextOnLaunchTethered) var autoContextOnLaunchTethered
    @Default(.appAppearance) private var appAppearance

    init() {
        // Always configure SwiftBeaver first to have logger working in initializers
        Self.configureSwiftBeaver()
        
        // For testing new user experience
        // clearTokens()
    }

    var body: some Scene {
        @Bindable var appState = appState
        
        // TODO: LOYD - Move the `onChange` stuff into AppDelegate
        Window("AppBackgroundUpdates", id: "appBackgroundUpdates") {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    if let window = NSApp.windows.first(where: { $0.title == "AppBackgroundUpdates" }) {
                        window.setFrame(NSRect(x: 0, y: 0, width: 1, height: 1), display: false)
                        window.isOpaque = false
                        window.hasShadow = false
                        window.backgroundColor = NSColor.clear
                        window.isReleasedWhenClosed = false
                        window.level = .floating
                        window.ignoresMouseEvents = true
                        window.styleMask = []
                        window.orderOut(nil)
                    }
                }
                .onChange(of: [
                    autoContextFromCurrentWindow,
                    autoContextFromHighlights,
                    autoContextOnLaunchTethered
                ], initial: true) { oldValue, newValue in
                    AnalyticsManager.Accessibility.flagsChanges()
                }
                .onChange(of: appAppearance, initial: true) { _, _ in
                    AppAppearance.applyCurrent()
                }
        }
        
        // TODO: LOYD - THIS WINDOW WAS ADDED BACK AFTER FIXING MAGIC LINK AUTH. I'm not sure why this was causing the auto-crashing issue, but adding it back as an inert invisble background window fixed it. I'll come back to this later. For now, this fixes the crash and doesn't affect the app at all.
        Window("URLHandler", id: "urlHandler") {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    if let window = NSApp.windows.first(where: { $0.title == "URLHandler" }) {
                        window.setFrame(NSRect(x: 0, y: 0, width: 1, height: 1), display: false)
                        window.isOpaque = false
                        window.hasShadow = false
                        window.backgroundColor = NSColor.clear
                        window.isReleasedWhenClosed = false
                        window.level = .floating
                        window.ignoresMouseEvents = true
                        window.styleMask = []
                        window.orderOut(nil)
                    }
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

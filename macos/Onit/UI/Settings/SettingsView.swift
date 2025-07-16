import KeyboardShortcuts
import SwiftUI
import Defaults

struct SettingsView: View {
    @Environment(\.appState) var appState
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared

    var body: some View {
        TabView(
            selection: Binding(
                get: { appState.settingsTab },
                set: {
                    AnalyticsManager.Settings.tabPressed(tabName: $0.rawValue)
                    appState.settingsTab = $0
                }
            )
        ) {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)

            ModelsTab()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(SettingsTab.models)
            
            SystemPromptTab()
                .tabItem {
                    Label("Prompts", systemImage: "message")
                }
                .tag(SettingsTab.prompts)

            ShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(SettingsTab.shortcuts)

            AccessibilityTab()
                .tabItem {
                    if accessibilityPermissionManager.accessibilityPermissionStatus == .granted {
                        Label("Context", systemImage: "lightbulb")
                    } else {
                        Label("Context", systemImage: "lightbulb.slash")
                    }
                }
                .tag(SettingsTab.accessibility)

            QuickEditTab()
                .tabItem {
                    Label("Quick Edit", systemImage: "wand.and.sparkles")
                }
                .tag(SettingsTab.quickEdit)
                
            WebSearchTab()
                .tabItem {
                    Label("Web Search", systemImage: "magnifyingglass")
                }
                .tag(SettingsTab.webSearch)

            #if DEBUG || BETA
            DatabaseSettingsView()
                .tabItem {
                    Label("Database", systemImage: "externaldrive")
                }
                .tag(SettingsTab.database)
            #endif

            #if DEBUG || BETA
                DebugModeTab()
                    .tabItem {
                        Label("Debug", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(SettingsTab.debug)
            #endif

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(idealWidth: 569, minHeight: 500)
        .fixedSize(horizontal: true, vertical: false)
        .onAppear {
            AnalyticsManager.Settings.opened(on: appState.settingsTab.rawValue)
        }
    }
}

#Preview {
    SettingsView()
}

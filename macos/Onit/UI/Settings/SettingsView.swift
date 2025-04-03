import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    var body: some View {
        TabView(
            selection: Binding(
                get: { model.settingsTab },
                set: { model.settingsTab = $0 }
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
                    if featureFlagsManager.accessibility {
                        Label("Context", systemImage: "lightbulb")
                    } else {
                        Label("Context", systemImage: "lightbulb.slash")
                    }
                }
                .tag(SettingsTab.accessibility)
                
            WebSearchTab()
                .tabItem {
                    Label("Web Search", systemImage: "magnifyingglass")
                }
                .tag(SettingsTab.webSearch)

            #if DEBUG
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
    }
}

#Preview {
    SettingsView()
}

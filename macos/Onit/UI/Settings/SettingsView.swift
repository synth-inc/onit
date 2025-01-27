import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(\.model) var model
    
    var body: some View {
        TabView(selection: Binding(
            get: { model.settingsTab },
            set: { model.settingsTab = $0 }
        )) {
            ModelsTab()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(SettingsTab.models)
            
            ShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(SettingsTab.shortcuts)
            
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

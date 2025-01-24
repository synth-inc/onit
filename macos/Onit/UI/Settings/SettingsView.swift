import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(\.model) var model
    
    var body: some View {
        TabView {
            ShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            ModelsTab()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
            
            #if DEBUG
            DebugModeTab()
                .tabItem {
                    Label("Debug", systemImage: "wrench.and.screwdriver")
                }
            #endif
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(idealWidth: 569, minHeight: 500)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    SettingsView()
}

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
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}

#Preview {
    SettingsView()
}

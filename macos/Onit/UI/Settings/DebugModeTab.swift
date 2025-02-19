import SwiftUI
import Defaults

struct DebugModeTab: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    @Default(.launchShortcutToggleEnabled) var launchShortcutToggleEnabled
    @Default(.createNewChatOnPanelOpen) var createNewChatOnPanelOpen

    var body: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Debug")
                    .font(.system(size: 14))
                HStack {
                    Text("Show debug window")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { model.showDebugWindow },
                            set: { model.showDebugWindow = $0 }
                        )
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                
                HStack {
                    Text("Launch shortcut toggle mode")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle(
                        "",
                        isOn: $launchShortcutToggleEnabled
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                HStack {
                    Text("Create new chat on panel open")
                        .font(.system(size: 13))
                        .help("When enabled, a new chat will be created each time the panel is opened after being closed. When disabled, the previous chat will be restored.")
                    Spacer()
                    Toggle(
                        "",
                        isOn: $createNewChatOnPanelOpen
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .help("When enabled, a new chat will be created each time the panel is opened after being closed. When disabled, the previous chat will be restored.")
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
}

#Preview {
    DebugModeTab()
}

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
                    SettingInfoButton(
                        title: "Launch Shortcut Toggle Mode",
                        description:
                            "Enable this to use the launch shortcut (CMD+Zero by default) as a toggle: press once to show the panel, press again to hide it.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
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
                    SettingInfoButton(
                        title: "Create New Chat on Panel Open",
                        description:
                            "Enable this to start a new chat each time the panel opens. You still access your previous conversations with the up arrow.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
                    Spacer()
                    Toggle(
                        "",
                        isOn: $createNewChatOnPanelOpen
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
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

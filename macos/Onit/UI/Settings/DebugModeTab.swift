import SwiftUI
import Defaults

struct DebugModeTab: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    @Default(.launchShortcutToggleEnabled) var launchShortcutToggleEnabled
    
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
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
}

#Preview {
    DebugModeTab()
}

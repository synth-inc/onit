import SwiftUI

struct DebugModeTab: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Debug")
                    .font(.system(size: 14))
                HStack {
                    Text("Show debug window")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { model.showDebugWindow },
                        set: { model.showDebugWindow = $0 }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
            VStack(alignment: .leading, spacing: 20) {
                Text("Feature flags")
                    .font(.system(size: 14))
                HStack {
                    Text("Accessibility")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { featureFlagsManager.flags.accessibility },
                        set: { featureFlagsManager.setFeatureFlag($0, for: .accessibility) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
}

#Preview {
    DebugModeTab()
} 

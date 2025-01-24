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
                
                featureFlagsView
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
    
    var featureFlagsView: some View {
        ForEach(FeatureFlagManager.FeatureFlagKey.allCases) { key in
            HStack {
                Text(key.rawValue)
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { featureFlagsManager.getFeatureFlag(key) },
                    set: { featureFlagsManager.setFeatureFlag($0, for: key) }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        }
    }
}

#Preview {
    DebugModeTab()
} 

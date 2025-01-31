import SwiftUI

struct DebugModeTab: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    // MARK: - Feature Flag Keys
    
    enum FeatureFlagKey: String, CaseIterable, Identifiable {
        var id : String { UUID().uuidString }
        
        case accessibility = "Accessibility"
        case accessibilityInput = "Accessibility Input"
        case accessibilityAutoContext = "Accessibility Auto Context"
    }
    
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
                
                featureFlagView(key: .accessibility)
                featureFlagView(key: .accessibilityInput)
                featureFlagView(key: .accessibilityAutoContext)
                
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
    
    func featureFlagView(key: FeatureFlagKey) -> some View {
        HStack {
            Text(key.rawValue)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: Binding(
                get: {
                    switch key {
                    case .accessibility:
                        featureFlagsManager.accessibility
                    case .accessibilityInput:
                        featureFlagsManager.accessibilityInput
                    case .accessibilityAutoContext:
                        featureFlagsManager.accessibilityAutoContext
                    }
                },
                set: {
                    switch key {
                    case .accessibility:
                        featureFlagsManager.overrideAccessibility($0)
                    case .accessibilityInput:
                        featureFlagsManager.overrideAccessibilityInput($0)
                    case .accessibilityAutoContext:
                        featureFlagsManager.overrideAccessibilityAutoContext($0)
                    }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }
}

#Preview {
    DebugModeTab()
} 

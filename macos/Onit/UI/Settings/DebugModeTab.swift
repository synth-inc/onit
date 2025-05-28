import SwiftUI
import Defaults

struct DebugModeTab: View {
    @ObservedObject private var debugManager = DebugManager.shared

    var body: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Debug")
                    .font(.system(size: 14))
                HStack {
                    Text("Show debug window")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $debugManager.showDebugWindow)
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

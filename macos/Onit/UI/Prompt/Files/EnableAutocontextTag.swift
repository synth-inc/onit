import SwiftUI

struct EnableAutocontextTag: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    @AppStorage("closedAutocontext") private var closedAutocontext = false
    
    var body: some View {
        HStack(spacing: 4) {
            Button {
                closedAutocontext = true
                model.settingsTab = .accessibility
                openSettings()
            } label: {
                Image(.stars)
                    .resizable()
                    .frame(width: 12, height: 12)
                Text("Enable Auto-Context Context")
                    .appFont(.medium13)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 3)
            Button {
                closedAutocontext = true
            } label: {
                Color.clear
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(.smallCross)
                    }
            }
        }
        .padding(.horizontal, 4)
        .background(Color(.blue300).opacity(0.25), in: .rect(cornerRadius: 4))
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        EnableAutocontextTag()
    }
}
#endif

import SwiftUI
import Defaults

struct EnableAutocontextTag: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings

    @Default(.closedAutoContextTag) var closedAutoContextTag
    
    var body: some View {
        HStack(spacing: 4) {
            Button {
                closedAutoContextTag = true
                appState.settingsTab = .accessibility
                openSettings()
            } label: {
                Image(.stars)
                    .resizable()
                    .frame(width: 12, height: 12)
                Text("Enable AutoContext")
                    .appFont(.medium13)
                    .foregroundStyle(Color.S_0)
            }
            .padding(.vertical, 3)
            Button {
                closedAutoContextTag = true
            } label: {
                Color.clear
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(.smallCross)
                            .renderingMode(.template)
                            .foregroundColor(Color.S_0)
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
        EnableAutocontextTag()
    }
#endif

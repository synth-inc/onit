import SwiftUI

struct SettingInfoButton: View {
    let title: String
    let description: String
    let defaultValue: String
    let valueType: String

    @State private var showTooltip: Bool = false

    var body: some View {
        Button {
            showTooltip.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.primary.opacity(0.65))
                .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                Divider()
                Group {
                    Text("Type: ").font(.system(size: 12, weight: .medium))
                        + Text(valueType).font(.system(size: 12))
                }
                Group {
                    Text("Default: ").font(.system(size: 12, weight: .medium))
                        + Text(defaultValue).font(.system(size: 12))
                }
            }
            .padding(12)
            .frame(width: 300)
        }
    }
}

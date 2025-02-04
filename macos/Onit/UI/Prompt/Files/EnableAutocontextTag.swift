import SwiftUI

struct EnableAutocontextTag: View {
    @Environment(\.model) var model
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            Button {
                isVisible = false
                model.showSettings(tab: .accessibility)
            } label: {
                HStack(spacing: 4) {
                    Image(.stars)
                        .resizable()
                        .frame(width: 12, height: 12)
                    
                    Text("Enable Autocontext Context")
                        .appFont(.medium13)
                        .foregroundStyle(.white)
                }
                .padding(3)
                .background(Color(.blue300).opacity(0.25), in: .rect(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        EnableAutocontextTag()
    }
}
#endif
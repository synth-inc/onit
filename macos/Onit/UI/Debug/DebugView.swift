import SwiftUI

struct DebugView: View {
    @ObservedObject private var debugManager = DebugManager.shared

    var body: some View {
        VStack {
            HStack {
                Button {
                    debugManager.showDebugWindow = false
                } label: {
                    Image(.smallCross)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            
            ScrollView {
                TextEditor(text: $debugManager.debugText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
            }
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

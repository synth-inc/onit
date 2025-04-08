import SwiftUI

struct DebugView: View {
    @ObservedObject private var debugManager = DebugManager.shared

    var body: some View {
        ScrollView {
            TextEditor(text: $debugManager.debugText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(12)
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

import SwiftUI

struct DebugView: View {
    @Environment(\.model) var model
    
    var body: some View {
        ScrollView {
            TextEditor(text: Binding(get: { model.debugText ?? "" }, set: { model.debugText = $0 }))
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

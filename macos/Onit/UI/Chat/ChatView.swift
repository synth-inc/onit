import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model
    @AppStorage("seenLocal") var seenLocal = false
    
    var body: some View {
        VStack(spacing: 0) {
            ChatsView()
            SetUpDialogs(seenLocal: seenLocal)
            FileRow(contextList: model.pendingContextList)
            TextInputView()
        }
        .drag()
        .onChange(of: model.availableLocalModels.count) { _, new in
            if new != 0 {
                seenLocal = true
            }
        }
        .onChange(of: model.currentPrompts) { _, new in
            // Trigger a UI update when currentPrompts changes
        }
    }
}

#Preview {
    ChatView()
}

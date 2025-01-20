import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model
    @AppStorage("seenLocal") var seenLocal = false

    var body: some View {
        VStack(spacing: 0) {
            ChatsView()
            SetUpDialogs(seenLocal: seenLocal)
            InputBarView()
        }
        .drag()
        .onChange(of: model.preferences.availableLocalModels.count) { _, new in
            if new != 0 {
                seenLocal = true
            }
        }
    }
}

#Preview {
    ChatView()
}

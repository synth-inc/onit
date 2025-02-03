import SwiftUI
import Defaults

struct ChatView: View {
    @Environment(\.model) var model
    @AppStorage("seenLocal") var seenLocal = false
    @Default(.availableLocalModels) var availableLocalModels

    var body: some View {
        VStack(spacing: 0) {
            SetUpDialogs(seenLocal: seenLocal)
            ChatsView()
            InputBarView()
        }
        .drag()
        .onChange(of: availableLocalModels.count) { _, new in
            if new != 0 {
                seenLocal = true
            }
        }
    }
}

#Preview {
    ChatView()
}

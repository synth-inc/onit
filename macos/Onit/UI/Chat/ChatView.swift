import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model

    @Default(.availableLocalModels) var availableLocalModels

    var body: some View {
        VStack(spacing: 0) {
            SetUpDialogs()
            ChatsView()
            InputBarView()
        }
        .drag()
    }
}

#Preview {
    ChatView()
}

import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model

    @Default(.availableLocalModels) var availableLocalModels

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IncognitoDismissable()
            SetUpDialogs()
            if let systemPrompt = model.currentChat?.systemPrompt {
                ChatSystemPromptView(systemPrompt: systemPrompt)
            }
            ChatsView()
            InputBarView()
        }
        .drag()
    }
}

#Preview {
    ChatView()
}

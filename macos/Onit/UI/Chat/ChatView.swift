import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model

    @Default(.availableLocalModels) var availableLocalModels
    
    private var shouldShowSystemPrompt: Bool {
        model.currentChat?.systemPrompt == nil && SystemPromptState.shared.shouldShowSystemPrompt
    }
    
    private var currentPromptsCount: Int {
        if let currentPrompts = model.currentPrompts {
            return currentPrompts.count
        } else {
            return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SetUpDialogs()
            
            systemPrompts
            
            ChatsView(currentPromptsCount: currentPromptsCount)
            
            PromptCore()
            
            // Kept here for testing purposes.
            // This is effectively deprecated, so it should be deleted eventually.
//            InputBarView()
            
            if currentPromptsCount <= 0 { Spacer() }
        }
        .drag()
    }
}

// MARK: - Child Components

extension ChatView {
    var systemPrompts: some View {
        Group {
            if let systemPrompt = model.currentChat?.systemPrompt {
                ChatSystemPromptView(systemPrompt: systemPrompt)
            }
            
            if currentPromptsCount > 0 { PromptDivider() }
            
            if shouldShowSystemPrompt { SystemPromptView() }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}

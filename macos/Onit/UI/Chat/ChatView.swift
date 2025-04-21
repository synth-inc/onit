import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.windowState) private var state
    
    private var shouldShowSystemPrompt: Bool {
        state.currentChat?.systemPrompt == nil && state.systemPromptState.shouldShowSystemPrompt
    }
    
    private var currentPromptsCount: Int {
        if let currentPrompts = state.currentPrompts {
            return currentPrompts.count
        } else {
            return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SetUpDialogs()
            
            systemPrompt
            
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
    var systemPrompt: some View {
        Group {
            if let systemPrompt = state.currentChat?.systemPrompt {
                ChatSystemPromptView(systemPrompt: systemPrompt)
                
                if currentPromptsCount > 0 {
                    PromptDivider()
                }
            }
            
            if shouldShowSystemPrompt {
                SystemPromptView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}

import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.windowState) private var state
    
    @State private var debounceTimer: Timer?
    @State private var finalScrollTimer: Timer?
    
    private var chatsID: Int? {
        state.currentChat?.hashValue
    }
    
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
            
            if currentPromptsCount > 0 {
                ScrollViewReader { proxy in
                    ScrollView {
                        systemPrompt
                        ChatsView()
                            .id(chatsID)
                            .onAppear {
                                scrollToBottom(using: proxy)
                            }
                    }
                    .onChange(of: state.streamedResponse) { old, new in
                        scrollToBottom(using: proxy)
                    }
                    .onChange(of: state.currentChat) { old, new in
                        scrollToBottom(using: proxy)
                    }
                    .padding(.top, 0)
                }
            } else {
                systemPrompt
            }
            
            PromptCore()
            
            // Kept here for testing purposes. When testing, comment out `PromptCore()`.
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
        VStack(alignment: .leading, spacing: 0) {
            if let systemPrompt = state.currentChat?.systemPrompt {
                ChatSystemPromptView(systemPrompt: systemPrompt)
            }
            if shouldShowSystemPrompt { SystemPromptView() }
        }
    }
}

// MARK: - Private Functions

extension ChatView {
    @MainActor
    private func scrollToBottom(using proxy: ScrollViewProxy) {
        finalScrollTimer?.invalidate()
        debounceTimer?.invalidate()
        
        let currentChatsID = chatsID
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.smooth(duration: 0.1)) {
                    proxy.scrollTo(
                        currentChatsID,
                        anchor: .bottom
                    )
                }
                
                // Schedule a final scroll after content is likely fully rendered
                self.finalScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    Task { @MainActor in
                        withAnimation(.smooth(duration: 0.1)) {
                            proxy.scrollTo(currentChatsID, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}

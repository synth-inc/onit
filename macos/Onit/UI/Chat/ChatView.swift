import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.windowState) private var state
    
    @State private var autoScrollTimer: Timer?
    @State private var autoScrollTimeoutTimer: Timer?
    @State private var isAutoScrolling: Bool = false
    
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
                                startAutoScrolling(using: proxy)
                            }
                            .onDisappear {
                                stopAutoScrolling()
                            }
                    }
                    .onChange(of: state.streamedResponse) { old, new in
                        startAutoScrolling(using: proxy)
                    }
                    .onChange(of: state.currentChat) { old, new in
                        startAutoScrolling(using: proxy)
                    }
                    .padding(.top, 0)
                }
            } else {
                systemPrompt
            }
            
            PromptCore(currentPromptsCount: currentPromptsCount)
            
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
    private func startAutoScrolling(using proxy: ScrollViewProxy) {
        if isAutoScrolling {
            resetAutoScrollTimeout(using: proxy)
            return
        }
        
        stopAutoScrolling()
        isAutoScrolling = true
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.scrollToBottom(using: proxy)
            }
        }
        
        scrollToBottom(using: proxy)
        resetAutoScrollTimeout(using: proxy)
    }
    
    @MainActor
    private func resetAutoScrollTimeout(using proxy: ScrollViewProxy) {
        autoScrollTimeoutTimer?.invalidate()
        autoScrollTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task { @MainActor in
                self.stopAutoScrolling()
                self.scrollToBottom(using: proxy)
            }
        }
    }
    
    @MainActor
    private func scrollToBottom(using proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.1)) {
            if let id = chatsID {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
    
    @MainActor
    private func stopAutoScrolling() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        autoScrollTimeoutTimer?.invalidate()
        autoScrollTimeoutTimer = nil
        isAutoScrolling = false
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}

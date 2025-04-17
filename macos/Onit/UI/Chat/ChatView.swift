import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.windowState) private var state

    @Default(.availableLocalModels) var availableLocalModels
    
    @State private var debounceTimer: Timer?
    @State private var finalScrollTimer: Timer?
    
    private var chatsID: Int? {
        state.currentChat?.hashValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    SetUpDialogs()
                    if let systemPrompt = state.currentChat?.systemPrompt {
                        ChatSystemPromptView(systemPrompt: systemPrompt)
                    }
                    ChatsView()
                        .id(chatsID)
                        .onAppear {
                            scrollToBottom(using: proxy)
                        }
                }
                .onChange(of: state.streamedResponse) {
                    scrollToBottom(using: proxy)
                }
                .onChange(of: state.currentChat) { old, new in
                    scrollToBottom(using: proxy)
                }
            }
            
            InputBarView()
        }
        .drag()
    }
    
    @MainActor
    private func scrollToBottom(using proxy: ScrollViewProxy) {
        finalScrollTimer?.invalidate()
        debounceTimer?.invalidate()
        
        let currentChatsID = chatsID
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.smooth(duration: 0.1)) {
                    proxy.scrollTo(currentChatsID, anchor: .bottom)
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

#Preview {
    ChatView()
}

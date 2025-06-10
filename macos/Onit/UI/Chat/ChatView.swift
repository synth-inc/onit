import Defaults
import SwiftUI

struct ChatView: View {
    @Environment(\.windowState) private var state
    
    @State private var hasUserManuallyScrolled: Bool = false
    @State private var chatChangeTask: Task<Void, Never>?
    
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
                ZStack(alignment: .bottom) {
                    ChatScrollViewRepresentable(
                        hasUserManuallyScrolled: $hasUserManuallyScrolled,
                        streamedResponse: state.streamedResponse,
                        currentChat: state.currentChat
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            systemPrompt
                            ChatsView()
                                .id(chatsID)
                                .onAppear {
                                    hasUserManuallyScrolled = false
                                }
                        }
                    }
                    
                    if hasUserManuallyScrolled {
                        HStack {
                            Spacer()
                            IconButton(
                                icon: .arrowDown,
                                buttonSize: 36,
                                action: {
                                    hasUserManuallyScrolled = false
                                },
                                activeColor: .white,
                                inactiveColor: .white,
                                tooltipPrompt: "Scroll to bottom",
                                hoverBackgroundColor: .gray400
                            )
                            .background(.gray600)
                            .addBorder(cornerRadius: 18, stroke: .gray400)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.trailing, 20)
                        }
                        .padding(.bottom, 4)
                    }
                }
                .onChange(of: state.currentChat) { old, new in
					chatChangeTask?.cancel()
                    hasUserManuallyScrolled = true
                    chatChangeTask = Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        
                        if !Task.isCancelled {
                            await MainActor.run {
                                hasUserManuallyScrolled = false
                            }
                        }
                    }
                }
            } else {
                systemPrompt
            }
            
            PromptCore()
            
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

// MARK: - Preview

#Preview {
    ChatView()
}

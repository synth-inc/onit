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
                    // Floating action buttons area
                    if state.generatingPrompt != nil || hasUserManuallyScrolled {
                        HStack {
                            Spacer()
                            
                            if state.generatingPrompt != nil {
                                StopGenerationButton()
                                    .offset(x: 18, y: 0) // This centers it to account for the scroll button frame
                            }
                            
                            Spacer()
                            
                            if hasUserManuallyScrolled {
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
                            } else {
                                // Placeholders.
                                Color.clear
                                    .frame(width: 36, height: 36)
                                    .padding(.trailing, 20)
                            }
                        }
                        .background(.clear)
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

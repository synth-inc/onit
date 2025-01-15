import SwiftUI

struct ChatView: View {
    @Environment(\.model) var model
    @AppStorage("seenLocal") var seenLocal = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let chat = model.currentChat {
                        ForEach(chat.prompts) { prompt in
                            PromptView(prompt: prompt)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            
            if case .error(let error) = model.generationState {
                GeneratedErrorView(error: error)
            }
            SetUpDialogs(seenLocal: seenLocal)
            FileRow()
            TextInputView()
        }
        .drag()
        .onChange(of: model.availableLocalModels.count) { _, new in
            if new != 0 {
                seenLocal = true
            }
        }
    }
}
import SwiftUI
import Defaults

extension TextInputView {
    func sendAction() {
        let inputText = (model.pendingInstruction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !inputText.isEmpty else { return }
        
        if model.isWebSearchEnabled {
            model.createAndSavePromptWithWebSearch()
        } else {
            model.createAndSavePrompt()
        }
    }
}

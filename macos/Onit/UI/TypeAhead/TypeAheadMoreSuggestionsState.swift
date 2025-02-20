//
//  TypeAheadMoreSuggestionsState.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import Defaults
import SwiftUI

@Observable
@MainActor
final class TypeAheadMoreSuggestionsState {
    
    // MARK: - Singleton instance
    
    @MainActor
    static let shared = TypeAheadMoreSuggestionsState()
    
    // MARK: - Properties
    
    var moreSuggestions: [String] = []
    var isLoading = false
    var error: TypeAheadError?
    
    // MARK: - Functions
    
    func getMoreSuggestions() async {
        let config = Defaults[.typeAheadConfig]
        
        guard let model = config.model else {
            error = TypeAheadError.noModelConfigured
            return
        }
        
        let userInput = AccessibilityNotificationsManager.shared.userInput
        guard !userInput.fullText.isEmpty else {
            error = TypeAheadError.noUserInput
            return
        }
        
        let systemMessage = TypeAheadPrompts.MoreSuggestions.systemPrompt
        let instruction = TypeAheadPrompts.MoreSuggestions.systemPrompt + TypeAheadPrompts.MoreSuggestions.instruction(userInput: userInput)
        
        do {
            isLoading = true
            moreSuggestions = try await Task.detached {
                do {
                    let response = try await FetchingClient().localGenerate(
                        systemMessage: systemMessage,
                        prompt: instruction,
                        model: model,
                        keepAlive: config.keepAlive,
                        options: config.options
                    )
                    return [response]
                } catch {
                    throw error
                }
            }.value
            isLoading = false
        } catch {
            self.isLoading = false
            self.error = .moreSuggestionFailed(error.localizedDescription)
        }
    }
}

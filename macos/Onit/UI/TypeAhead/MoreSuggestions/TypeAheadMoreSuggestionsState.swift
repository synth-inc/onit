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
    var hoveredIndex: Int? = nil
    var isLoading = false
    var error: TypeAheadError?
    
    // MARK: - Functions
    
    func reset(error: TypeAheadError? = nil) {
        moreSuggestions = []
        hoveredIndex = nil
        isLoading = false
        self.error = error
    }
    
    func getMoreSuggestions() async {
        isLoading = true
        let config = Defaults[.typeAheadConfig]
        
        guard let model = config.model else {
            reset(error: TypeAheadError.noModelConfigured)
            return
        }
        
        let userInput = AccessibilityNotificationsManager.shared.userInput
        guard !userInput.fullText.isEmpty else {
            reset(error: TypeAheadError.noUserInput)
            return
        }
        
        let systemMessage = TypeAheadPrompts.MoreSuggestions.systemPrompt
        let instruction = TypeAheadPrompts.MoreSuggestions.systemPrompt + TypeAheadPrompts.MoreSuggestions.instruction(userInput: userInput)
        
        do {
            moreSuggestions = try await Task.detached {
                do {
                    let response = try await FetchingClient().localGenerate(
                        systemMessage: systemMessage,
                        prompt: instruction,
                        model: model,
                        keepAlive: config.keepAlive,
                        options: config.options
                    )
                    return response.split(separator: "\n").map { String($0) }
                } catch {
                    throw error
                }
            }.value
            isLoading = false
        } catch {
            reset(error: .moreSuggestionFailed(error.localizedDescription))
        }
    }
}

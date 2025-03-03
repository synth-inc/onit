//
//  TypeaheadAutocompletionService.swift
//  Onit
//
//  Created by Kévin Naudin on 03/03/2025.
//

import SwiftUI

actor TypeaheadAutocompletionService {
    static let shared = TypeaheadAutocompletionService()
    
    func generateSuggestion(
        userInput: AccessibilityUserInput,
        screenResult: ScreenResult,
        model: String,
        config: TypeaheadConfig
    ) async throws -> AsyncThrowingStream<String, Error> {
        let localMessages = await buildLocalChatMessages(input: userInput, screenResult: screenResult)
        
        if config.streamResponse {
            return try await StreamingClient().localChat(
                model: model,
                localMessages: localMessages,
                keepAlive: config.keepAlive,
                options: config.options
            )
        } else {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let response = try await FetchingClient().localChat(
                            model: model,
                            localMessages: localMessages,
                            keepAlive: config.keepAlive,
                            options: config.options
                        )
                        
                        continuation.yield(response)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    private func buildLocalChatMessages(input: AccessibilityUserInput, screenResult: ScreenResult) async -> [LocalChatMessage] {
        var localMessageStack: [LocalChatMessage] = []
        let similarCases = await TypeaheadLearningService.shared.findSimilarCases(
            input: input,
            screenResult: screenResult
        )
        let formattedExamples = formatExamples(from: similarCases)
        let systemMessage = TypeAheadPrompts.AutoCompletion.systemPrompt + formattedExamples
        let instruction = TypeAheadPrompts.AutoCompletion.instruction(input: input, screenResult: screenResult)
        
        localMessageStack.append(LocalChatMessage(role: "system", content: systemMessage, images: nil))
        localMessageStack.append(LocalChatMessage(role: "user", content: instruction, images: nil))
        
        print("\(localMessageStack)")
        return localMessageStack
    }
    
    private func formatExamples(from examples: [TypeaheadExample]) -> String {
        guard !examples.isEmpty else {
            return ""
        }
        
        return "GOOD EXAMPLES (Follow this format):\n" +
            examples.map { example in
                TypeAheadPrompts.AutoCompletion.sample(data: example)
            }.joined(separator: "\n\n")
    }
} 

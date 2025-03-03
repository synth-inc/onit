//
//  TypeaheadSuggestionService.swift
//  Onit
//
//  Created by Kévin Naudin on 03/03/2025.
//

import SwiftUI

actor TypeaheadSuggestionService {
    static let shared = TypeaheadSuggestionService()
    
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
        let systemMessage = """
        You are an assistant that helps complete text intelligently.
        You must analyze the application context and the text already entered to suggest the most relevant completion.
        Respond only with the completion text, without explanations or formatting.
        """
        
        localMessageStack.append(LocalChatMessage(role: "system", content: systemMessage, images: []))
        
        let instruction = formatInstruction(input: input, screenResult: screenResult)
        let formattedExamples = formatExamples(from: similarCases, currentInput: input.fullText)
        
        localMessageStack.append(LocalChatMessage(role: "user", content: instruction, images: []))
        localMessageStack.append(contentsOf: formattedExamples)
        
        return localMessageStack
    }
    
    private func formatInstruction(input: AccessibilityUserInput, screenResult: ScreenResult) -> String {
        let application = screenResult.applicationName ?? ""
        let windowTitle = screenResult.applicationTitle ?? ""
        let screenContent = screenResult.others?["screen"] ?? ""
        let currentText = input.fullText
        let precedingText = input.precedingText
        let followingText = input.followingText
        
        return """
        In the application "\(application)", window "\(windowTitle)", 
        the user has typed: "\(currentText)"

        Screen context:
        \(screenContent)

        Text before cursor: "\(precedingText)"
        Text after cursor: "\(followingText)"

        Complete the text in a natural and relevant way.
        """
    }
    
    private func formatExamples(from examples: [TypeaheadExample], currentInput: String) -> [LocalChatMessage] {
        examples.map { example in
            let content = """
            Previous example in the application "\(example.applicationName)", window "\(example.windowTitle)", 
            the user has typed: "\(example.currentText)"

            Screen context:
            \(example.screenContent)

            Text before cursor: "\(example.precedingText)"
            Text after cursor: "\(example.followingText)"

            Complete the text in a natural and relevant way.
            """
            
            return LocalChatMessage(role: "assistant", content: content, images: nil)
        }
    }
} 

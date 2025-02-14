//
//  AutoCompleteService.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import Foundation

class AutoCompleteService {
    static func complete() async throws -> AsyncThrowingStream<String, Error> {
        let config = Defaults[.typeAheadConfig]
        
        guard let model = config.model else {
            throw AutoCompleteError.noModelConfigured
        }
        
        let userInput = await AccessibilityNotificationsManager.shared.userInput
        guard userInput != .empty else {
            throw AutoCompleteError.noUserInput
        }
        
        let appName = await AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "l'application"
        
        let systemMessage = """
        You are an auto-completion assistant specialized in text prediction.
        
        IMPORTANT RULES:
        1. NEVER repeat the already typed text
        2. ONLY provide the logical continuation of the text
        3. Stay concise and natural
        4. Respect style and context
        5. Answer in a single line
        6. Do not add punctuation at the beginning
        """
        
        let instruction = """
        TEXT TO COMPLETE:
        
        Before cursor: "\(userInput.precedingText)"
        [CURSOR HERE]
        After cursor: "\(userInput.followingText)"
        
        Complete the text from the cursor position.
        """
        
        let instructions = [instruction]
        let inputs: [Input?] = [nil]
        let files: [[URL]] = [[]]
        let images: [[URL]] = [[]]
        let autoContexts: [[String: String]] = [[:]]
        let responses: [String] = []
        
        if config.streamResponse {
            return try await StreamingClient().localChat(
                systemMessage: systemMessage,
                instructions: instructions,
                inputs: inputs,
                files: files,
                images: images,
                autoContexts: autoContexts,
                responses: responses,
                model: model,
                options: config.options
            )
        } else {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let response = try await FetchingClient().localChat(
                            systemMessage: systemMessage,
                            instructions: instructions,
                            inputs: inputs,
                            files: files,
                            images: images,
                            autoContexts: autoContexts,
                            responses: responses,
                            model: model,
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
}

enum AutoCompleteError: Error {
    case noModelConfigured
    case noUserInput
    case completionFailed(String)
}

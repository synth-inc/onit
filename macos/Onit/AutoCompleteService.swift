//
//  AutoCompleteService.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import Foundation

class AutoCompleteService {
    static func complete(text: String) async throws -> AsyncThrowingStream<String, Error> {
        let config = Defaults[.typeAheadConfig]
        
        guard let model = config.model else {
            throw AutoCompleteError.noModelConfigured
        }
        
        let systemMessage = """
        You are an auto-completion assistant. Complete the given text naturally, 
        continuing the user's thought or sentence. Provide only the completion, 
        no explanations or additional context.
        """
        
        let instructions = [text]
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
    case completionFailed(String)
}

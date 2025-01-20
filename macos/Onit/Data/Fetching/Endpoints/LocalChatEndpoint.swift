//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Foundation
import PhotosUI

extension FetchingClient {
    func localChat(instructions: [String], inputs: [Input?], files: [[URL]], images: [[URL]], responses: [String], model: String?) async throws -> String {

        guard let model = model else {
            throw FetchingError.invalidRequest(message: "Model is required")
        }
        
        guard instructions.count == inputs.count,
              inputs.count == files.count,
              files.count == images.count,
              images.count == responses.count + 1 else {
            throw FetchingError.invalidRequest(message: "Mismatched array lengths: instructions, inputs, files, and images must be the same length, and one longer than responses.")
        }

        let systemMessage = "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go."

         // Create the user messages by appending any text files
        var userMessages: [String] = []
        for (index, instruction) in instructions.enumerated() {
            var message = ""
            
            if let input = inputs[index], !input.selectedText.isEmpty {
                if let application = input.application {
                    message += "\n\nSelected Text from \(application): \(input.selectedText)"
                } else {
                    message += "\n\nSelected Text: \(input.selectedText)"
                }
            }
            
            // TODO: add error handling for contexts too long & incorrect file types
            if !files[index].isEmpty {
                for file in files[index] {
                    if let fileContent = try? String(contentsOf: file, encoding: .utf8) {
                        message += "\n\nFile: \(file.lastPathComponent)\nContent:\n\(fileContent)"
                    }
                }
            }

            // Intuitively, I (tim) think the message should be the last thing. 
            // TODO: evaluate this 
            message += "\n\n\(instruction)"
            userMessages.append(message)
        }

        var localMessageStack: [LocalChatMessage] = []
        localMessageStack.append(LocalChatMessage(role: "system", content: systemMessage, images: []))

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                localMessageStack.append(LocalChatMessage(role: "user", content: userMessage, images: []))
            } else {
                var base64Images : [String] = []
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        base64Images.append(base64EncodedData)
                    }
                }
                localMessageStack.append(LocalChatMessage(role: "user", content: userMessage, images: base64Images))
            }

            if index < responses.count {
                localMessageStack.append(LocalChatMessage(role: "assistant", content: responses[index], images: nil))
            }
        }
        
        let endpoint = LocalChatEndpoint(model: model, messages: localMessageStack)
        let response = try await execute(endpoint)
        return response.message.content
    }
}

struct LocalChatEndpoint: Endpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalChatRequestJSON
    typealias Response = LocalChatResponseJSON

    let model: String?
    let messages: [LocalChatMessage]
    var baseURL: URL  = URL(string: "http://localhost:11434")!
    
    var path: String { "/api/chat" }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var requestBody: LocalChatRequestJSON? {
        LocalChatRequestJSON(model: model, messages: messages)
    }

}

// TODO change this to match the expected request
struct LocalChatRequestJSON: Codable {
    let model: String?
    let messages: [LocalChatMessage]
//    var format : String = "json"
    var stream : Bool = false
}

struct LocalChatMessage: Codable {
    let role: String
    let content: String
    let images: [String]?
}

struct LocalChatResponseJSON: Codable {
    let model: String
    let created_at: String
    let message: LocalChatMessageResponse
    let done_reason: String
    let done: Bool
    let total_duration: Int
    let load_duration: Int
    let prompt_eval_count: Int
    let prompt_eval_duration: Int
    let eval_count: Int
    let eval_duration: Int
}

struct LocalChatMessageResponse: Codable {
    let role: String
    let content: String
}


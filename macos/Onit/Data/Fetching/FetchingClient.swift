//
//  FetchingClient.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation
import UniformTypeIdentifiers

actor FetchingClient {
    let session = URLSession.shared
    let encoder = JSONEncoder()
    let decoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
 
    func chat(instructions: [String], inputs: [Input?], files: [[URL]], images: [[URL]], responses: [String], model: AIModel?, apiToken: String?) async throws -> String {
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
        
        switch model.provider {
        case .openAI:

            var openAIMessageStack: [OpenAIChatMessage] = []

            // Initialize messages with system prompt if needed
            if model.supportsSystemPrompts {
                openAIMessageStack.append(OpenAIChatMessage(role: "system", content: .text(systemMessage)))
            }
            
            for (index, userMessage) in userMessages.enumerated() {
                if images[index].isEmpty {
                    let openAIMessage = OpenAIChatMessage(role: "user", content: .text(userMessage))
                    openAIMessageStack.append(openAIMessage)
                } else {
                    var parts = [OpenAIChatContentPart(type: "text", text: userMessage, image_url: nil)]
                    for url in images[index] {
                        if let imageData = try? Data(contentsOf: url) {
                            let base64EncodedData = imageData.base64EncodedString()
                            let mimeType = mimeType(for: url)
                            let imagePart = OpenAIChatContentPart(
                                type: "image_url",
                                text: nil,
                                image_url: .init(url: "data:\(mimeType);base64,\(base64EncodedData)")
                            )
                            parts.append(imagePart)
                        } else {
                            print("Unable to read image data from URL: \(url)")
                        }
                    }
                    let openAIMessage = OpenAIChatMessage(role: "user", content: .multiContent(parts))
                    openAIMessageStack.append(openAIMessage)
                }
                
                // If there is a corresponding response, add it as an assistant message
                if index < responses.count {
                    let responseMessage = OpenAIChatMessage(role: "assistant", content: .text(responses[index]))
                    openAIMessageStack.append(responseMessage)
                }
            }

            let endpoint = OpenAIChatEndpoint(messages: openAIMessageStack, token: apiToken, model: model.id)
            let response = try await execute(endpoint)
            return response.choices[0].message.content
            
        case .anthropic:
            var anthropicMessageStack: [AnthropicMessage] = []
            for (index, userMessage) in userMessages.enumerated() {
                let content: [AnthropicContent]
                if images[index].isEmpty {
                    content = [AnthropicContent(type: "text", text: userMessage, source: nil)]
                } else {
                    content = [
                        AnthropicContent(type: "text", text: userMessage, source: nil)
                    ] + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = mimeType(for: url)
                        return AnthropicContent(
                            type: "image",
                            text: nil,
                            source: AnthropicImageSource(
                                type: "base64",
                                media_type: mimeType,
                                data: base64EncodedData
                            )
                        )
                    }
                }
                
                anthropicMessageStack.append(AnthropicMessage(role: "user", content: content))
                
                // If there is a corresponding response, add it as an assistant message
                if index < responses.count {
                    let assistantContent = [AnthropicContent(type: "text", text: responses[index], source: nil)]
                    let assistantMessage = AnthropicMessage(role: "assistant", content: assistantContent)
                    anthropicMessageStack.append(assistantMessage)
                }
            }
            
            let endpoint = AnthropicChatEndpoint(
                model: model.id,
                system: model.supportsSystemPrompts ? systemMessage : "",
                token: apiToken,
                messages: anthropicMessageStack,
                maxTokens: 4096
            )
            let response = try await execute(endpoint)
            return response.content[0].text
            
        case .xAI:
            var xAIMessageStack: [XAIChatMessage] = []

            // Initialize messages with system prompt if needed
            if model.supportsSystemPrompts {
                xAIMessageStack.append(XAIChatMessage(role: "system", content: .text(systemMessage)))
            }
            
            for (index, userMessage) in userMessages.enumerated() {
                if images[index].isEmpty {
                    xAIMessageStack.append(XAIChatMessage(role: "user", content: .text(userMessage)))
                } else {
                    let parts = [
                        XAIChatContentPart(type: "text", text: userMessage, image_url: nil)
                    ] + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = mimeType(for: url)
                        return XAIChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(url: "data:\(mimeType);base64,\(base64EncodedData)", detail: "high")
                        )
                    }
                    xAIMessageStack.append(XAIChatMessage(role: "user", content: .multiContent(parts)))
                }
                
                // If there is a corresponding response, add it as an assistant message
                if index < responses.count {
                    let responseMessage = XAIChatMessage(role: "assistant", content: .text(responses[index]))
                    xAIMessageStack.append(responseMessage)
                }
            }
            
            let endpoint = XAIChatEndpoint(messages: xAIMessageStack, model: model.id, token: apiToken)
            let response = try await execute(endpoint)
            return response.choices[0].message.content
            
        case .googleAI:
            var googleAIMessageStack: [GoogleAIChatMessage] = []
            
            for (index, userMessage) in userMessages.enumerated() {
                var parts: [GoogleAIChatPart] = []
                
                // Add text part
                parts.append(GoogleAIChatPart(text: userMessage, inlineData: nil))
                
                // Add image parts if any
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = mimeType(for: url)
                        parts.append(GoogleAIChatPart(
                            text: nil,
                            inlineData: GoogleAIChatInlineData(
                                mimeType: mimeType,
                                data: base64EncodedData
                            )
                        ))
                    } else {
                        print("Unable to read image data from URL: \(url)")
                    }
                }
                
                // Add user message
                googleAIMessageStack.append(GoogleAIChatMessage(role: "user", parts: parts))
                
                // If there is a corresponding response, add it as a model message
                if index < responses.count {
                    let responseMessage = GoogleAIChatMessage(
                        role: "model",
                        parts: [GoogleAIChatPart(text: responses[index], inlineData: nil)]
                    )
                    googleAIMessageStack.append(responseMessage)
                }
            }
            
            let endpoint = GoogleAIChatEndpoint(messages: googleAIMessageStack, model: model.id, token: apiToken)
            let response = try await execute(endpoint)
            return response.candidates[0].content.parts[0].text
        }
    }
    
    func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension
        if let uti = UTType(filenameExtension: pathExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream" // Fallback if MIME type is not found
    }
}

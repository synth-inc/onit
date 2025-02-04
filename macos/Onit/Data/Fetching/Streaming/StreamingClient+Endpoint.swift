//
//  StreamingClient+Endpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 04/02/2025.
//

import Foundation

extension StreamingClient {
    
    // MARK: - OpenAI
    
    func buildOpenAIChatEndpoint(model: AIModel,
                                 images: [[URL]],
                                 responses: [String],
                                 apiToken: String?,
                                 systemMessage: String,
                                 userMessages: [String]) -> OpenAIChatEndpoint {
        var openAIMessageStack: [OpenAIChatMessage] = []
        
        if model.supportsSystemPrompts == true {
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
                        let mimeType = url.mimeType
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
        
        return OpenAIChatEndpoint(messages: openAIMessageStack, token: apiToken, model: model.id)
    }
    
    // MARK: - Anthropic
    
    func buildAnthropicChatEndpoint(model: AIModel,
                                    images: [[URL]],
                                    responses: [String],
                                    apiToken: String?,
                                    systemMessage: String,
                                    userMessages: [String]) -> AnthropicChatEndpoint {
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
                    let mimeType = url.mimeType
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
        
        return AnthropicChatEndpoint(
            model: model.id,
            system: model.supportsSystemPrompts ? systemMessage : "",
            token: apiToken,
            messages: anthropicMessageStack,
            maxTokens: 4096
        )
    }
    
    // MARK: - xAI
    
    func buildXAIChatEndpoint(model: AIModel,
                              images: [[URL]],
                              responses: [String],
                              apiToken: String?,
                              systemMessage: String,
                              userMessages: [String]) -> XAIChatEndpoint {
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
                    let mimeType = url.mimeType
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
        
        return XAIChatEndpoint(messages: xAIMessageStack, model: model.id, token: apiToken)
    }
    
    // MARK: - GoogleAI
    
    func buildGoogleAIChatEndpoint(model: AIModel,
                                   images: [[URL]],
                                   responses: [String],
                                   apiToken: String?,
                                   systemMessage: String,
                                   userMessages: [String]) -> GoogleAIChatEndpoint {
        // For compatibility, the Google AI API is set up to respond to messages in the same format as OpenAI
        // So this exactly duplicates the OpenAI API structure.
        var googleAIMessageStack: [GoogleAIChatMessage] = []
        
        if model.supportsSystemPrompts {
            googleAIMessageStack.append(GoogleAIChatMessage(role: "system", content: .text(systemMessage)))
        }
        
        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                googleAIMessageStack.append(GoogleAIChatMessage(role: "user", content: .text(userMessage)))
            } else {
                let parts = [
                    GoogleAIChatContentPart(type: "text", text: userMessage, image_url: nil)
                ] + images[index].compactMap { url in
                    guard let imageData = try? Data(contentsOf: url) else {
                        print("Unable to read image data from URL: \(url)")
                        return nil
                    }
                    let base64EncodedData = imageData.base64EncodedString()
                    let mimeType = url.mimeType
                    return GoogleAIChatContentPart(
                        type: "image_url",
                        text: nil,
                        image_url: .init(url: "data:\(mimeType);base64,\(base64EncodedData)")
                    )
                }
                googleAIMessageStack.append(GoogleAIChatMessage(role: "user", content: .multiContent(parts)))
            }
            
            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = GoogleAIChatMessage(role: "assistant", content: .text(responses[index]))
                googleAIMessageStack.append(responseMessage)
            }
        }
        
        return GoogleAIChatEndpoint(messages: googleAIMessageStack, model: model.id, token: apiToken)
    }
}

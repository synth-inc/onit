//
//  FetchingClient+Stream.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

import EventSource
import Foundation

extension FetchingClient {
    
    func chatInStream(llmRequest: LLMRequest, apiToken: String?) async throws -> AsyncThrowingStream<String, Error> {
        guard let model = llmRequest.model else {
            throw FetchingError.invalidRequest(message: "Model is required")
        }
        
        guard llmRequest.instructions.count == llmRequest.inputs.count,
              llmRequest.inputs.count == llmRequest.files.count,
              llmRequest.files.count == llmRequest.images.count,
              llmRequest.images.count == llmRequest.autoContexts.count,
              llmRequest.autoContexts.count == llmRequest.responses.count + 1 else {
            throw FetchingError.invalidRequest(message: "Mismatched array lengths: instructions, inputs, files, and images must be the same length, and one longer than responses.")
        }
        
        let systemMessage = "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go."
        let userMessages = buildUserMessages(llmRequest: llmRequest)
        
        let endpoint: any Endpoint
        switch model.provider {
        case .openAI:
            endpoint = buildOpenAIChatEndpoint(model: model,
                                               images: llmRequest.images,
                                               responses: llmRequest.responses,
                                               apiToken: apiToken,
                                               systemMessage: systemMessage,
                                               userMessages: userMessages)
        case .anthropic:
            endpoint = buildAnthropicChatEndpoint(model: model,
                                                  images: llmRequest.images,
                                                  responses: llmRequest.responses,
                                                  apiToken: apiToken,
                                                  systemMessage: systemMessage,
                                                  userMessages: userMessages)
        case .xAI:
            endpoint = buildXAIChatEndpoint(model: model,
                                            images: llmRequest.images,
                                            responses: llmRequest.responses,
                                            apiToken: apiToken,
                                            systemMessage: systemMessage,
                                            userMessages: userMessages)
        case .googleAI:
            endpoint = buildGoogleAIChatEndpoint(model: model,
                                                 images: llmRequest.images,
                                                 responses: llmRequest.responses,
                                                 apiToken: apiToken,
                                                 systemMessage: systemMessage,
                                                 userMessages: userMessages)
        }
        
        return try await stream(endpoint: endpoint)
    }
    
    // MARK: - Streaming
    
    private func stream(endpoint: any Endpoint) async throws -> AsyncThrowingStream<String, Error> {
        let urlRequest = try endpoint.asURLRequest()
        let eventSource = EventSource(mode: .dataOnly)
        let dataTask = await eventSource.dataTask(for: urlRequest)
        
        return AsyncThrowingStream<String, Error>(String.self, bufferingPolicy: .bufferingNewest(5)) { continuation in
            let task = Task { @Sendable in
                for await event in await dataTask.events() {
                    switch event {
                    case .event(let event):
                        if let response = try? endpoint.getContentFromSSE(event: event) {
                            continuation.yield(response)
                        }
                    case .error(let error):
                        print("KNA - error")
                        continuation.finish(throwing: error)
                    case .closed:
                        print("KNA - closed")
                        continuation.finish()
                    default:
                        break
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                Task {
                    await dataTask.cancel()
                }
            }
        }
    }
    
    // MARK: - User messages
    
    private func buildUserMessages(llmRequest: LLMRequest) -> [String] {
        var userMessages: [String] = []
        
        for (index, instruction) in llmRequest.instructions.enumerated() {
            var message = ""
            
            if let input = llmRequest.inputs[index], !input.selectedText.isEmpty {
                if let application = input.application {
                    message += "\n\nSelected Text from \(application): \(input.selectedText)"
                } else {
                    message += "\n\nSelected Text: \(input.selectedText)"
                }
            }
            
            if !llmRequest.files[index].isEmpty {
                for file in llmRequest.files[index] {
                    if let fileContent = try? String(contentsOf: file, encoding: .utf8) {
                        message += "\n\nFile: \(file.lastPathComponent)\nContent:\n\(fileContent)"
                    }
                }
            }
            
            if !llmRequest.autoContexts[index].isEmpty {
                for (appName, appContent) in llmRequest.autoContexts[index] {
                    message += "\n\nContent from application \(appName):\n\(appContent)"
                }
            }

            // Intuitively, I (tim) think the message should be the last thing.
            // TODO: evaluate this
            message += "\n\n\(instruction)"
            print(message)
            userMessages.append(message)
        }
        
        return userMessages
    }
    
    // MARK: - OpenAI
    
    private func buildOpenAIChatEndpoint(model: AIModel,
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
        
        return OpenAIChatEndpoint(messages: openAIMessageStack, token: apiToken, model: model.id)
    }
    
    // MARK: - Anthropic
    
    private func buildAnthropicChatEndpoint(model: AIModel,
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
        
        return AnthropicChatEndpoint(
            model: model.id,
            system: model.supportsSystemPrompts ? systemMessage : "",
            token: apiToken,
            messages: anthropicMessageStack,
            maxTokens: 4096
        )
    }
    
    // MARK: - xAI
    
    private func buildXAIChatEndpoint(model: AIModel,
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
        
        return XAIChatEndpoint(messages: xAIMessageStack, model: model.id, token: apiToken)
    }
    
    // MARK: - GoogleAI
    
    private func buildGoogleAIChatEndpoint(model: AIModel,
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
                    let mimeType = mimeType(for: url)
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

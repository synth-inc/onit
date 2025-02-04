//
//  StreamingClient.swift
//  Onit
//
//  Created by Kévin Naudin on 04/02/2025.
//

import EventSource
import Foundation

actor StreamingClient {
    
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
                    case .open:
                        break
                    case .event(let event):
                        if let response = try? endpoint.getContentFromSSE(event: event) {
                            continuation.yield(response)
                        }
                    case .error(let error):
                        continuation.finish(throwing: convertError(endpoint: endpoint, error: error))
                    case .closed:
                        continuation.finish()
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
}

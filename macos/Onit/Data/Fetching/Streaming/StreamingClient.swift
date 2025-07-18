//
//  StreamingClient.swift
//  Onit
//
//  Created by Kévin Naudin on 04/02/2025.
//

import EventSource
import Foundation
import Defaults

actor StreamingClient {

    func chat(systemMessage: String,
              instructions: [String],
              inputs: [[Input]],
              files: [[URL]],
              images: [[URL]],
              autoContexts: [[String: String]],
              webSearchContexts: [[(title: String, content: String, source: String, url: URL?)]],
              responses: [String],
              tools: [Tool],
              useOnitServer: Bool,
              model: AIModel,
              apiToken: String?,
              includeSearch: Bool? = nil) async throws -> AsyncThrowingStream<StreamingEndpointResponse, Error> {
        let userMessages = ChatEndpointMessagesBuilder.user(
            instructions: instructions,
            inputs: inputs,
            files: files,
            autoContexts: autoContexts,
            webSearchContexts: webSearchContexts)
        let endpoint = try await ChatStreamingEndpointBuilder.build(
            useOnitServer: useOnitServer,
            model: model,
            images: images,
            responses: responses,
            apiToken: apiToken,
            systemMessage: systemMessage,
            userMessages: userMessages,
            tools: tools,
            includeSearch: includeSearch)
        var eventParser: EventParser?
        
        if !useOnitServer && model.provider == .googleAI {
            // Reusing this event parser because it also fix the same bug with GoogleAI
            eventParser = PerplexityEventParser()
        }

        if !useOnitServer && model.provider == .perplexity {
            eventParser = PerplexityEventParser()
        }

        return try await stream(endpoint: endpoint, eventParser: eventParser)
    }
    
    func localChat(systemMessage: String,
                   instructions: [String],
                   inputs: [[Input]],
                   files: [[URL]],
                   images: [[URL]],
                   autoContexts: [[String: String]],
                   webSearchContexts: [[(title: String, content: String, source: String, url: URL?)]],
                   responses: [String],
                   model: String) async throws -> AsyncThrowingStream<StreamingEndpointResponse, Error> {
        let userMessages = ChatEndpointMessagesBuilder.user(
            instructions: instructions,
            inputs: inputs,
            files: files,
            autoContexts: autoContexts,
            webSearchContexts: webSearchContexts)
        let localMessages = ChatEndpointMessagesBuilder.local(
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)
        let endpoint = LocalChatStreamingEndpoint(model: model, messages: localMessages)
        
        return try await stream(endpoint: endpoint, eventParser: LocalEventParser())
    }

    // MARK: - Streaming

    private func stream(endpoint: any StreamingEndpoint, eventParser: EventParser? = nil) async throws
        -> AsyncThrowingStream<StreamingEndpointResponse, Error>
    {
        let urlRequest = try endpoint.asURLRequest()
        let eventSource = EventSource(eventParser: eventParser)
        let dataTask = await eventSource.dataTask(for: urlRequest)
        
        #if DEBUG
        // Helpful debugging method- put in the endpoint name and you can see the full request
        if endpoint.baseURL.absoluteString.contains("api.perplexity.ai") {
            let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
            FetchingClient.printCurlRequest(endpoint: endpoint, url: url)
        }
        #endif
        
        return AsyncThrowingStream<StreamingEndpointResponse, Error>(
            StreamingEndpointResponse.self, bufferingPolicy: .unbounded
        ) { continuation in
            let task = Task { @Sendable in
                for await event in await dataTask.events() {
                    switch event {
                    case .open:
                        break
                    case .event(let event):
                        if let response = try? endpoint.getContentFromSSE(event: event) {
                            continuation.yield(response)
                        } else {
                            continuation.yield(StreamingEndpointResponse(content: nil, toolName: nil, toolArguments: nil))
                        }
                    case .error(let error):
                        continuation.finish(
                            throwing: convertError(
                                endpoint: endpoint, error: error))
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
}

//
//  FetchingClient.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import UniformTypeIdentifiers

struct ChatResponse {
    let content: String?
    let toolName: String?
    let toolArguments: String?
}

actor FetchingClient {
    let encoder = JSONEncoder()
    let decoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    func chat(
        systemMessage: String,
        instructions: [String],
        inputs: [Input?],
        files: [[URL]],
        images: [[URL]],
        autoContexts: [[String: String]],
        webSearchContexts: [[(title: String, content: String, source: String, url: URL?)]],
        responses: [String],
        model: AIModel,
        apiToken: String?,
        tools: [Tool] = [],
        includeSearch: Bool? = nil
    ) async throws -> ChatResponse {
        let userMessages = ChatEndpointMessagesBuilder.user(
            instructions: instructions,
            inputs: inputs,
            files: files,
            autoContexts: autoContexts,
            webSearchContexts: webSearchContexts)
        
        let endpoint = try await ChatEndpointBuilder.build(
            model: model,
            images: images,
            responses: responses,
            apiToken: apiToken,
            systemMessage: systemMessage,
            userMessages: userMessages,
            tools: tools,
            includeSearch: includeSearch)
        
        return try await fetchChatContent(from: endpoint)
    }
    
    private func fetchChatContent<E: Endpoint>(from endpoint: E) async throws -> ChatResponse {
        let response = try await execute(endpoint)
        
        if let toolResponse = endpoint.getToolResponse(response: response) {
            return toolResponse
        }
        
        guard let content = endpoint.getContent(response: response) else {
            throw FetchingError.noContent
        }
        return ChatResponse(content: content, toolName: nil, toolArguments: nil)
    }
    
    func localChat(
        systemMessage: String,
        instructions: [String],
        inputs: [Input?],
        files: [[URL]],
        images: [[URL]],
        autoContexts: [[String: String]],
        webSearchContexts: [[(title: String, content: String, source: String, url: URL?)]],
        responses: [String],
        model: String,
        tools: [Tool] = []
    ) async throws -> ChatResponse {
         // Create the user messages by appending any text files
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
        
        let endpoint = LocalChatEndpoint(
			model: model,
			messages: localMessages,
			tools: tools)
		
        return try await fetchChatContent(from: endpoint)
    }
}

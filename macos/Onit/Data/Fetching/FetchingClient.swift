//
//  FetchingClient.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import UniformTypeIdentifiers

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
        apiToken: String?
    ) async throws -> String {
        let userMessages = ChatEndpointMessagesBuilder.user(
            instructions: instructions,
            inputs: inputs,
            files: files,
            autoContexts: autoContexts,
            webSearchContexts: webSearchContexts)
        
        let endpoint = try ChatEndpointBuilder.build(
            model: model,
            images: images,
            responses: responses,
            apiToken: apiToken,
            systemMessage: systemMessage,
            userMessages: userMessages)
        
        return try await fetchChatContent(from: endpoint)
    }
    
    private func fetchChatContent<E: Endpoint>(from endpoint: E) async throws -> String {
        let response = try await execute(endpoint)
        guard let content = endpoint.getContent(response: response) else {
            throw FetchingError.noContent
        }
        return content
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
        model: String
    ) async throws -> String {
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
        
        let endpoint = LocalChatEndpoint(model: model, messages: localMessages)
        let response = try await execute(endpoint)
        return response.message.content
    }
}

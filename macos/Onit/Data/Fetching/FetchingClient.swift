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
    let session = URLSession.shared
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
        keepAlive: String?,
        options: LocalChatOptions
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
        
        return try await localChat(model: model, localMessages: localMessages, keepAlive: keepAlive, options: options)
    }
    
    func localChat(model: String,
                   localMessages: [LocalChatMessage],
                   keepAlive: String?,
                   options: LocalChatOptions) async throws -> String {
        let endpoint = LocalChatEndpoint(model: model, messages: localMessages, keepAlive: keepAlive, options: options)
        let response = try await execute(endpoint)
        
        return response.message.content
    }
    
    func localGenerate(
        systemMessage: String,
        prompt: String,
        model: String,
        keepAlive: String?,
        options: LocalChatOptions
    ) async throws -> String {
        let endpoint = LocalGenerateEndpoint(model: model, prompt: prompt, system: systemMessage, keepAlive: keepAlive, options: options)
        let response = try await execute(endpoint)
        
        return response.response
    }
    
    private func fetchChatContent<E: Endpoint>(from endpoint: E) async throws -> String {
        let response = try await execute(endpoint)
        guard let content = endpoint.getContent(response: response) else {
            throw FetchingError.noContent
        }
        return content
    }
}

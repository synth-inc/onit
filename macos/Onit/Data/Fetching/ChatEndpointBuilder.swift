//
//  ChatEndpointBuilder.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Defaults
import Foundation

struct ChatEndpointBuilder {

    static func build(
        useOnitServer: Bool,
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool] = [],
        includeSearch: Bool? = nil
    ) async throws -> any Endpoint {
        if useOnitServer {
            let messages = ChatEndpointMessagesBuilder.onit(
                model: model,
                images: images,
                responses: responses,
                systemMessage: systemMessage,
                userMessages: userMessages)
            
            return OnitChatStreamingEndpoint(
                model: model.id, messages: messages, tools: tools, includeSearch: includeSearch)
        }
        switch model.provider {
        case .openAI:
            return await ChatEndpointBuilder.openAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        case .anthropic:
            return await ChatEndpointBuilder.anthropic(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        case .xAI:
            return ChatEndpointBuilder.xAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .googleAI:
            return ChatEndpointBuilder.googleAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        case .deepSeek:
            return ChatEndpointBuilder.deepSeek(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .perplexity:
            return ChatEndpointBuilder.perplexity(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .custom:
            return try ChatEndpointBuilder.custom(
                model: model,
                images: images,
                responses: responses,
                systemMessage: systemMessage,
                userMessages: userMessages)
        }
    }

    private static func openAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool] = [],
        includeSearch: Bool? = nil
    ) async -> OpenAIChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.openAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        var searchTool: ChatSearchTool?
        if includeSearch == true {
            searchTool = try? await FetchingClient().getChatSearchTool(provider: "OpenAI")
        }

        return OpenAIChatEndpoint(
            messages: messages, token: apiToken, model: model.id, supportsToolCalling: model.supportsToolCalling, tools: tools, searchTool: searchTool)
    }

    private static func anthropic(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool] = [],
        includeSearch: Bool? = nil
    ) async -> AnthropicChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.anthropic(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        var searchTool: ChatSearchTool?
        if includeSearch == true {
            searchTool = try? await FetchingClient().getChatSearchTool(provider: "Anthropic")
        }

        return AnthropicChatEndpoint(
            model: model.id,
            system: model.supportsSystemPrompts ? systemMessage : "",
            token: apiToken,
            messages: messages,
            maxTokens: 4096,
            supportsToolCalling: model.supportsToolCalling,
            tools: tools,
            searchTool: searchTool
        )
    }

    private static func xAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> XAIChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.xAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return XAIChatEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func googleAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool] = [],
        includeSearch: Bool? = nil
    ) -> GoogleAIChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.googleAI(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        return GoogleAIChatEndpoint(
            messages: messages,
            system: model.supportsSystemPrompts ? systemMessage : nil,
            model: model.id,
            queryToken: apiToken,
            supportsToolCalling: model.supportsToolCalling,
            tools: tools,
            includeSearch: includeSearch)
    }

    private static func deepSeek(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> DeepSeekChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.deepSeek(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return DeepSeekChatEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func perplexity(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> PerplexityChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.perplexity(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)
        return PerplexityChatEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func custom(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) throws -> CustomChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.custom(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        guard
            let customProvider = Defaults[.availableCustomProviders].first(
                where: { $0.name == model.customProviderName })
        else {
            throw FetchingError.invalidRequest(
                message: "Custom provider not found")
        }

        let url = URL(string: customProvider.baseURL)!

        return CustomChatEndpoint(
            baseURL: url, messages: messages, token: customProvider.token, model: model.id)
    }
}

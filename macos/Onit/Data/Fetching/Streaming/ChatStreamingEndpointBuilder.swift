//
//  ChatStreamingEndpointBuilder.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Defaults
import Foundation

/// Used to build the Chat streaming endpoint
struct ChatStreamingEndpointBuilder {

    static func build(
        useOnitServer: Bool,
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool],
        includeSearch: Bool? = nil
    ) async throws -> any StreamingEndpoint {
        if useOnitServer {
            return ChatStreamingEndpointBuilder.onit(
                model: model,
                images: images,
                responses: responses,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        }
        switch model.provider {
        case .openAI:
            return await ChatStreamingEndpointBuilder.openAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        case .anthropic:
            return await ChatStreamingEndpointBuilder.anthropic(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                tools: tools,
                includeSearch: includeSearch)
        case .xAI:
            return ChatStreamingEndpointBuilder.xAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .googleAI:
            return ChatStreamingEndpointBuilder.googleAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                includeSearch: includeSearch)
        case .deepSeek:
            return ChatStreamingEndpointBuilder.deepSeek(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .perplexity:
            return ChatStreamingEndpointBuilder.perplexity(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .custom:
            return try ChatStreamingEndpointBuilder.custom(
                model: model,
                images: images,
                responses: responses,
                systemMessage: systemMessage,
                userMessages: userMessages)
        }
    }

    private static func onit(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String],
        tools: [Tool],
        includeSearch: Bool? = nil
    ) -> OnitChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.onit(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return OnitChatStreamingEndpoint(
            model: model.id, messages: messages, tools: tools, includeSearch: includeSearch)
    }

    private static func openAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool],
        includeSearch: Bool? = nil
    ) async -> OpenAIChatStreamingEndpoint {
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

        return OpenAIChatStreamingEndpoint(
            messages: messages, token: apiToken, model: model.id, supportsToolCalling: model.supportsToolCalling, tools: tools, searchTool: searchTool)
    }

    private static func anthropic(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        tools: [Tool],
        includeSearch: Bool? = nil
    ) async -> AnthropicChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.anthropic(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        var searchTool: ChatSearchTool?
        if includeSearch == true {
            searchTool = try? await FetchingClient().getChatSearchTool(provider: "Anthropic")
        }

        return AnthropicChatStreamingEndpoint(
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
    ) -> XAIChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.xAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return XAIChatStreamingEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func googleAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        includeSearch: Bool? = nil
    ) -> GoogleAIChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.googleAI(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        return GoogleAIChatStreamingEndpoint(
            messages: messages,
            system: model.supportsSystemPrompts ? systemMessage : nil,
            model: model.id,
            queryToken: apiToken,
            includeSearch: includeSearch)
    }

    private static func deepSeek(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> DeepSeekChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.deepSeek(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return DeepSeekChatStreamingEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func perplexity(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> PerplexityChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.perplexity(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return PerplexityChatStreamingEndpoint(
            messages: messages, model: model.id, token: apiToken)
    }

    private static func custom(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) throws -> CustomChatStreamingEndpoint {
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

        return CustomChatStreamingEndpoint(
            baseURL: url, messages: messages, token: customProvider.token,
            model: model.id)
    }
}

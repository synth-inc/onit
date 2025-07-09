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
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        includeSearch: Bool? = nil
    ) throws -> any Endpoint {
        switch model.provider {
        case .openAI:
            return ChatEndpointBuilder.openAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
                includeSearch: includeSearch)
        case .anthropic:
            return ChatEndpointBuilder.anthropic(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages,
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
        includeSearch: Bool? = nil
    ) -> OpenAIChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.openAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return OpenAIChatEndpoint(
            messages: messages, token: apiToken, model: model.id, includeSearch: includeSearch)
    }

    private static func anthropic(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String],
        includeSearch: Bool? = nil
    ) -> AnthropicChatEndpoint {
        let messages = ChatEndpointMessagesBuilder.anthropic(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        return AnthropicChatEndpoint(
            model: model.id,
            system: model.supportsSystemPrompts ? systemMessage : "",
            token: apiToken,
            messages: messages,
            maxTokens: 4096,
            includeSearch: includeSearch
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

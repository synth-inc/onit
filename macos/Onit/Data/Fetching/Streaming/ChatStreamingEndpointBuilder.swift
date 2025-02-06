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
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) throws -> any StreamingEndpoint {
        switch model.provider {
        case .openAI:
            return ChatStreamingEndpointBuilder.openAI(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
        case .anthropic:
            return ChatStreamingEndpointBuilder.anthropic(
                model: model,
                images: images,
                responses: responses,
                apiToken: apiToken,
                systemMessage: systemMessage,
                userMessages: userMessages)
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
                userMessages: userMessages)
        case .deepSeek:
            return ChatStreamingEndpointBuilder.deepSeek(
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
                apiToken: apiToken,
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
        userMessages: [String]
    ) -> OpenAIChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.openAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return OpenAIChatStreamingEndpoint(
            messages: messages, token: apiToken, model: model.id)
    }

    private static func anthropic(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
        systemMessage: String,
        userMessages: [String]
    ) -> AnthropicChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.anthropic(
            model: model,
            images: images,
            responses: responses,
            userMessages: userMessages)

        return AnthropicChatStreamingEndpoint(
            model: model.id,
            system: model.supportsSystemPrompts ? systemMessage : "",
            token: apiToken,
            messages: messages,
            maxTokens: 4096
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
        userMessages: [String]
    ) -> GoogleAIChatStreamingEndpoint {
        let messages = ChatEndpointMessagesBuilder.googleAI(
            model: model,
            images: images,
            responses: responses,
            systemMessage: systemMessage,
            userMessages: userMessages)

        return GoogleAIChatStreamingEndpoint(
            messages: messages, model: model.id, token: apiToken)
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

    private static func custom(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        apiToken: String?,
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

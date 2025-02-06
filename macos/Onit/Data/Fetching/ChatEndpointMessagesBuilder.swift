//
//  ChatEndpointMessagesBuilder.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Foundation

/**
 * Used to build the messages in chat endpoints's request
 */
struct ChatEndpointMessagesBuilder {

    // MARK: - OpenAI

    static func openAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [OpenAIChatMessage] {
        var openAIMessageStack: [OpenAIChatMessage] = []

        if model.supportsSystemPrompts == true {
            openAIMessageStack.append(
                OpenAIChatMessage(role: "system", content: .text(systemMessage))
            )
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                let openAIMessage = OpenAIChatMessage(
                    role: "user", content: .text(userMessage))
                openAIMessageStack.append(openAIMessage)
            } else {
                var parts = [
                    OpenAIChatContentPart(
                        type: "text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = OpenAIChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(
                                url:
                                    "data:\(mimeType);base64,\(base64EncodedData)"
                            )
                        )
                        parts.append(imagePart)
                    } else {
                        print("Unable to read image data from URL: \(url)")
                    }
                }
                let openAIMessage = OpenAIChatMessage(
                    role: "user", content: .multiContent(parts))
                openAIMessageStack.append(openAIMessage)
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = OpenAIChatMessage(
                    role: "assistant", content: .text(responses[index]))
                openAIMessageStack.append(responseMessage)
            }
        }

        return openAIMessageStack
    }

    // MARK: - Anthropic

    static func anthropic(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        userMessages: [String]
    ) -> [AnthropicMessage] {
        var anthropicMessageStack: [AnthropicMessage] = []

        for (index, userMessage) in userMessages.enumerated() {
            let content: [AnthropicContent]
            if images[index].isEmpty {
                content = [
                    AnthropicContent(
                        type: "text", text: userMessage, source: nil)
                ]
            } else {
                content =
                    [
                        AnthropicContent(
                            type: "text", text: userMessage, source: nil)
                    ]
                    + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
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

            anthropicMessageStack.append(
                AnthropicMessage(role: "user", content: content))

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let assistantContent = [
                    AnthropicContent(
                        type: "text", text: responses[index], source: nil)
                ]
                let assistantMessage = AnthropicMessage(
                    role: "assistant", content: assistantContent)
                anthropicMessageStack.append(assistantMessage)
            }
        }

        return anthropicMessageStack
    }

    // MARK: - xAI

    static func xAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [XAIChatMessage] {
        var xAIMessageStack: [XAIChatMessage] = []

        // Initialize messages with system prompt if needed
        if model.supportsSystemPrompts {
            xAIMessageStack.append(
                XAIChatMessage(role: "system", content: .text(systemMessage)))
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                xAIMessageStack.append(
                    XAIChatMessage(role: "user", content: .text(userMessage)))
            } else {
                let parts =
                    [
                        XAIChatContentPart(
                            type: "text", text: userMessage, image_url: nil)
                    ]
                    + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        return XAIChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(
                                url:
                                    "data:\(mimeType);base64,\(base64EncodedData)",
                                detail: "high")
                        )
                    }
                xAIMessageStack.append(
                    XAIChatMessage(role: "user", content: .multiContent(parts)))
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = XAIChatMessage(
                    role: "assistant", content: .text(responses[index]))
                xAIMessageStack.append(responseMessage)
            }
        }

        return xAIMessageStack
    }

    // MARK: - GoogleAI

    static func googleAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [GoogleAIChatMessage] {
        // For compatibility, the Google AI API is set up to respond to messages in the same format as OpenAI
        // So this exactly duplicates the OpenAI API structure.
        var googleAIMessageStack: [GoogleAIChatMessage] = []

        if model.supportsSystemPrompts {
            googleAIMessageStack.append(
                GoogleAIChatMessage(
                    role: "system", content: .text(systemMessage)))
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                googleAIMessageStack.append(
                    GoogleAIChatMessage(
                        role: "user", content: .text(userMessage)))
            } else {
                let parts =
                    [
                        GoogleAIChatContentPart(
                            type: "text", text: userMessage, image_url: nil)
                    ]
                    + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        return GoogleAIChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(
                                url:
                                    "data:\(mimeType);base64,\(base64EncodedData)"
                            )
                        )
                    }
                googleAIMessageStack.append(
                    GoogleAIChatMessage(
                        role: "user", content: .multiContent(parts)))
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = GoogleAIChatMessage(
                    role: "assistant", content: .text(responses[index]))
                googleAIMessageStack.append(responseMessage)
            }
        }

        return googleAIMessageStack
    }

    // MARK: - DeepSeek

    static func deepSeek(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [DeepSeekChatMessage] {
        var deepSeekMessageStack: [DeepSeekChatMessage] = []

        // DeepSeek uses OpenAI-compatible format
        if model.supportsSystemPrompts {
            deepSeekMessageStack.append(
                DeepSeekChatMessage(
                    role: "system", content: .text(systemMessage)))
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                deepSeekMessageStack.append(
                    DeepSeekChatMessage(
                        role: "user", content: .text(userMessage)))
            } else {
                var parts = [
                    DeepSeekChatContentPart(
                        type: "text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = DeepSeekChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(
                                url:
                                    "data:\(mimeType);base64,\(base64EncodedData)"
                            )
                        )
                        parts.append(imagePart)
                    } else {
                        print("Unable to read image data from URL: \(url)")
                    }
                }
                deepSeekMessageStack.append(
                    DeepSeekChatMessage(
                        role: "user", content: .multiContent(parts)))
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = DeepSeekChatMessage(
                    role: "assistant", content: .text(responses[index]))
                deepSeekMessageStack.append(responseMessage)
            }
        }

        return deepSeekMessageStack
    }

    // MARK: - Custom

    static func custom(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [OpenAIChatMessage] {
        var openAIMessageStack: [OpenAIChatMessage] = []

        // Initialize messages with system prompt if needed
        // if model.supportsSystemPrompts {

        // 3rd Party model providers don't tell us if system prompts are enabled or not...
        // How to handle? I guess the user needs to be able to toggle system prompts for each custom provider model.
        openAIMessageStack.append(
            OpenAIChatMessage(role: "system", content: .text(systemMessage)))

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                let openAIMessage = OpenAIChatMessage(
                    role: "user", content: .text(userMessage))
                openAIMessageStack.append(openAIMessage)
            } else {
                var parts = [
                    OpenAIChatContentPart(
                        type: "text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = OpenAIChatContentPart(
                            type: "image_url",
                            text: nil,
                            image_url: .init(
                                url:
                                    "data:\(mimeType);base64,\(base64EncodedData)"
                            )
                        )
                        parts.append(imagePart)
                    } else {
                        print("Unable to read image data from URL: \(url)")
                    }
                }
                let openAIMessage = OpenAIChatMessage(
                    role: "user", content: .multiContent(parts))
                openAIMessageStack.append(openAIMessage)
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = OpenAIChatMessage(
                    role: "assistant", content: .text(responses[index]))
                openAIMessageStack.append(responseMessage)
            }
        }

        return openAIMessageStack
    }
}

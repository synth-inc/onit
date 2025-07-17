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
    
    static func user(instructions: [String], inputs: [[Input]], files: [[URL]], autoContexts: [[String: String]], webSearchContexts: [[(title: String, content: String, source: String, url: URL?)]]) -> [String] {
        var userMessages: [String] = []
        for (index, instruction) in instructions.enumerated() {
            var message = ""
            
     
            // TODO: add error handling for contexts too long & incorrect file types
            if !files[index].isEmpty {
                message += "\n\nUse the following files as context:"
                for file in files[index] {
                    if let fileContent = try? String(contentsOf: file, encoding: .utf8) {
                        message += "\n\nFile: \(file.lastPathComponent)\nContent:\n\(fileContent)"
                    }
                }
            }
            
            if !autoContexts[index].isEmpty {
                message += "\n\nUse the following application content as context:"
                for (appName, appContent) in autoContexts[index] {
                    message += "\n\nContent from application \(appName):\n\(appContent)"
                }
            }
            
            // Add web contexts
            if index < webSearchContexts.count && !webSearchContexts[index].isEmpty {
                message += "\n\nUse the following web search results as context:"
                for webSearchContext in webSearchContexts[index] {
                    message += "\n\nWeb Search Result: \(webSearchContext.title)"
                    if !webSearchContext.source.isEmpty {
                        message += " (Source: \(webSearchContext.source))"
                    }
                    message += "\n\(webSearchContext.content)"
                }
            }
            
            if !inputs[index].isEmpty {
                let pendingInputs = inputs[index]
                
                message += "\n\nUse the following selected text as context. When present, selected text should take priority over other context."
                
                for input in pendingInputs {
                    if let application = input.application {
                        message += "\n\nSelected Text from \(application): \(input.selectedText)"
                    } else {
                        message += "\n\nSelected Text: \(input.selectedText)"
                    }
                }
            }
            
            // Intuitively, I (tim) think the message should be the last thing.
            // TODO: evaluate this
            message += "\n\n\(instruction)"
            userMessages.append(message)
        }

        return userMessages
    }
    
    // MARK: - Local
    
    static func local(
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [LocalChatMessage] {
        var localMessageStack: [LocalChatMessage] = []
        
        localMessageStack.append(LocalChatMessage(role: "system", content: systemMessage, images: []))

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                localMessageStack.append(LocalChatMessage(role: "user", content: userMessage, images: []))
            } else {
                var base64Images : [String] = []
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        base64Images.append(base64EncodedData)
                    }
                }
                localMessageStack.append(LocalChatMessage(role: "user", content: userMessage, images: base64Images))
            }

            if index < responses.count {
                localMessageStack.append(LocalChatMessage(role: "assistant", content: responses[index], images: nil))
            }
        }
        
        return localMessageStack
    }

    // MARK: - Onit

    static func onit(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [OnitChatMessage] {
        var onitMessageStack: [OnitChatMessage] = []

        if model.supportsSystemPrompts {
            onitMessageStack.append(
                OnitChatMessage(
                    role: "system",
                    content: [
                        OnitContent(
                            type: "text", text: systemMessage, source: nil)
                    ])
            )
        }

        for (index, userMessage) in userMessages.enumerated() {
            let content: [OnitContent]
            if images[index].isEmpty {
                content = [
                    OnitContent(
                        type: "text", text: userMessage, source: nil)
                ]
            } else {
                content =
                    [
                        OnitContent(
                            type: "text", text: userMessage, source: nil)
                    ]
                    + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        return OnitContent(
                            type: "image",
                            text: nil,
                            source: OnitImageSource(
                                mimeType: mimeType,
                                data: base64EncodedData
                            )
                        )
                    }
            }

            onitMessageStack.append(
                OnitChatMessage(role: "user", content: content))

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let assistantContent = [
                    OnitContent(
                        type: "text", text: responses[index], source: nil)
                ]
                let assistantMessage = OnitChatMessage(
                    role: "assistant", content: assistantContent)
                onitMessageStack.append(assistantMessage)
            }
        }

        return onitMessageStack
    }

    // MARK: - OpenAI

    static func openAI(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [OpenAIChatMessage] {
        var openAIMessageStack: [OpenAIChatMessage] = []

        if model.supportsSystemPrompts {
            openAIMessageStack.append(
                OpenAIChatMessage(role: "system", content: .text(systemMessage))
            )
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                let openAIMessage = OpenAIChatMessage(role: "user", content: .text(userMessage))
                openAIMessageStack.append(openAIMessage)
            } else {
                var parts = [
                    OpenAIChatContentPart(type: "input_text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = OpenAIChatContentPart(
                            type: "input_image",
                            text: nil,
                            image_url: "data:\(mimeType);base64,\(base64EncodedData)"
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
        userMessages: [String]
    ) -> [GoogleAIChatMessage] {
        var googleAIMessageStack: [GoogleAIChatMessage] = []

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                googleAIMessageStack.append(
                    GoogleAIChatMessage(
                        role: "user",
                        parts: [GoogleAIChatPart(text: userMessage, inlineData: nil)]
                    )
                )
            } else {
                let parts =
                    [
                        GoogleAIChatPart(text: userMessage, inlineData: nil)
                    ]
                    + images[index].compactMap { url in
                        guard let imageData = try? Data(contentsOf: url) else {
                            print("Unable to read image data from URL: \(url)")
                            return nil
                        }
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        return GoogleAIChatPart(
                            text: nil,
                            inlineData: GoogleAIChatPart.InlineData(mimeType: mimeType, data: base64EncodedData)
                        )
                    }
                googleAIMessageStack.append(
                    GoogleAIChatMessage(role: "user", parts: parts))
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = GoogleAIChatMessage(
                    role: "model",
                    parts: [GoogleAIChatPart(text: responses[index], inlineData: nil)]
                )
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

    // MARK: - Perplexity

    static func perplexity(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [PerplexityChatMessage] {
        var perplexityMessageStack: [PerplexityChatMessage] = []

        // Add system message if supported
        if model.supportsSystemPrompts {
            perplexityMessageStack.append(
                PerplexityChatMessage(role: "system", content: .text(systemMessage)))
        }

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                let perplexityMessage = PerplexityChatMessage(
                    role: "user", content: .text(userMessage))
                perplexityMessageStack.append(perplexityMessage)
            } else {
                var parts = [
                    PerplexityChatContentPart(
                        type: "text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = PerplexityChatContentPart(
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
                let perplexityMessage = PerplexityChatMessage(
                    role: "user", content: .multiContent(parts))
                perplexityMessageStack.append(perplexityMessage)
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = PerplexityChatMessage(
                    role: "assistant", content: .text(responses[index]))
                perplexityMessageStack.append(responseMessage)
            }
        }

        return perplexityMessageStack
    }


    // MARK: - Custom

    static func custom(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [CustomChatMessage] {
        var customMessageStack: [CustomChatMessage] = []

        // Initialize messages with system prompt if needed
        // if model.supportsSystemPrompts {

        // 3rd Party model providers don't tell us if system prompts are enabled or not...
        // How to handle? I guess the user needs to be able to toggle system prompts for each custom provider model.
        customMessageStack.append(
            CustomChatMessage(role: "system", content: .text(systemMessage)))

        for (index, userMessage) in userMessages.enumerated() {
            if images[index].isEmpty {
                let customMessage = CustomChatMessage(
                    role: "user", content: .text(userMessage))
                customMessageStack.append(customMessage)
            } else {
                var parts = [
                    CustomChatContentPart(
                        type: "text", text: userMessage, image_url: nil)
                ]
                for url in images[index] {
                    if let imageData = try? Data(contentsOf: url) {
                        let base64EncodedData = imageData.base64EncodedString()
                        let mimeType = url.mimeType
                        let imagePart = CustomChatContentPart(
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
                let customMessage = CustomChatMessage(
                    role: "user", content: .multiContent(parts))
                customMessageStack.append(customMessage)
            }

            // If there is a corresponding response, add it as an assistant message
            if index < responses.count {
                let responseMessage = CustomChatMessage(
                    role: "assistant", content: .text(responses[index]))
                customMessageStack.append(responseMessage)
            }
        }

        return customMessageStack
    }
}

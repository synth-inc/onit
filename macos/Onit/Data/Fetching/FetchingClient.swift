//
//  FetchingClient.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation


actor ResponseManager {
    private var response: String = ""

    func append(_ content: String) {
        response += content
    }
    
    func getResponse() -> String {
        return response
    }
}
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
        _ text: String,
        input: Input?,
        model: AIModel?,
        token: String?,
        files: [URL],
        images: [URL],
        onProgress: (@Sendable (String) async -> Void)? = nil,
        onComplete: (@Sendable (String) async -> Void)? = nil
    ) async throws -> String {
        guard let model = model else {
            throw FetchingError.invalidRequest(message: "Model is required")
        }
        
        let systemMessage = input?.application != nil
            ? "Based on the provided instructions, either modify the given text from the application \(input!.application!) or answer any questions related to it. Provide the response without any additional comments. Provide the text ready to go."
            : "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go."
        
        // Combine all text inputs
        var userMessage = text
        if let selectedText = input?.selectedText {
            userMessage += "\n\nSelected Text: \(selectedText)"
        }
        
        // Add file contents if any
        if !files.isEmpty {
            for file in files {
                if let fileContent = try? String(contentsOf: file, encoding: .utf8) {
                    userMessage += "\n\nFile: \(file.lastPathComponent)\nContent:\n\(fileContent)"
                }
            }
        }
        
        switch model.provider {
        case .openAI:
            let messages: [OpenAIChatMessage]
            if images.isEmpty {
                messages = [
                    OpenAIChatMessage(role: "system", content: .text(systemMessage)),
                    OpenAIChatMessage(role: "user", content: .text(userMessage))
                ]
            } else {
                let parts = [
                    OpenAIChatContentPart(type: "text", text: userMessage, image_url: nil)
                ] + images.map { url in
                    OpenAIChatContentPart(
                        type: "image_url",
                        text: nil,
                        image_url: .init(url: url.absoluteString)
                    )
                }
                messages = [
                    OpenAIChatMessage(role: "system", content: .text(systemMessage)),
                    OpenAIChatMessage(role: "user", content: .multiContent(parts))
                ]
            }
            
            let endpoint = OpenAIChatEndpoint(messages: messages, model: model.rawValue, token: token)
            let responseManager = ResponseManager()
            try await executeStream(endpoint,
                onReceive: { content in
                    await responseManager.append(content)
                    let currentResponse = await responseManager.getResponse()
                    await onProgress?(currentResponse)
                },
                onComplete: {
                    let finalResponse = await responseManager.getResponse()
                    await onComplete?(finalResponse)
                }
            )
            return await responseManager.getResponse()
            
        case .anthropic:
            let content: [AnthropicContent]
            if images.isEmpty {
                content = [AnthropicContent(type: "text", text: userMessage, source: nil)]
            } else {
                content = [
                    AnthropicContent(type: "text", text: userMessage, source: nil)
                ] + images.map { url in
                    // Note: Anthropic requires base64 images, we'll need to convert URLs
                    // For now, we'll just reference them
                    AnthropicContent(
                        type: "image",
                        text: nil,
                        source: AnthropicImageSource(
                            type: "base64",
                            media_type: "image/jpeg",
                            data: url.absoluteString
                        )
                    )
                }
            }
            
            let messages = [AnthropicMessage(role: "user", content: content)]
            let endpoint = AnthropicChatEndpoint(
                model: model.rawValue,
                system: systemMessage,
                token: token,
                messages: messages,
                maxTokens: 4096
            )
            let responseManager = ResponseManager()
            try await executeStream(endpoint,
                onReceive: { content in
                    await responseManager.append(content)
                    let currentResponse = await responseManager.getResponse()
                    await onProgress?(currentResponse)
                },
                onComplete: {
                    let finalResponse = await responseManager.getResponse()
                    await onComplete?(finalResponse)
                }
            )
            return await responseManager.getResponse()
            
        case .xAI:
            let messages: [XAIChatMessage]
            if images.isEmpty {
                messages = [
                    XAIChatMessage(role: "system", content: .text(systemMessage)),
                    XAIChatMessage(role: "user", content: .text(userMessage))
                ]
            } else {
                let parts = [
                    XAIChatContentPart(type: "text", text: userMessage, image: nil)
                ] + images.map { url in
                    XAIChatContentPart(
                        type: "image",
                        text: nil,
                        image: .init(url: url.absoluteString, base64: nil)
                    )
                }
                messages = [
                    XAIChatMessage(role: "system", content: .text(systemMessage)),
                    XAIChatMessage(role: "user", content: .multiContent(parts))
                ]
            }
            
            let endpoint = XAIChatEndpoint(messages: messages, model: model.rawValue, token: token)
            let responseManager = ResponseManager()
            try await executeStream(endpoint,
                onReceive: { content in
                    await responseManager.append(content)
                    let currentResponse = await responseManager.getResponse()
                    await onProgress?(currentResponse)
                },
                onComplete: {
                    let finalResponse = await responseManager.getResponse()
                    await onComplete?(finalResponse)
                }
            )
            return await responseManager.getResponse()
        }
    }
}

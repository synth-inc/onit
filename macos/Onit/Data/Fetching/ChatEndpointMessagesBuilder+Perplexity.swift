import Foundation

extension ChatEndpointMessagesBuilder {
    static func perplexity(
        model: AIModel,
        images: [[URL]],
        responses: [String],
        systemMessage: String,
        userMessages: [String]
    ) -> [PerplexityChatMessage] {
        var messages = [PerplexityChatMessage]()
        
        // Add system message if provided
        if !systemMessage.isEmpty {
            messages.append(PerplexityChatMessage(role: "system", content: .text(systemMessage)))
        }
        
        // Iterate over user messages and corresponding responses if available
        for (index, userMessage) in userMessages.enumerated() {
            messages.append(PerplexityChatMessage(role: "user", content: .text(userMessage)))
            if index < responses.count {
                let response = responses[index]
                messages.append(PerplexityChatMessage(role: "assistant", content: .text(response)))
            }
        }
        
        // Optionally, incorporate images (for now, include their absoluteString joined if available)
        for imageGroup in images {
            let imageDescriptions = imageGroup.map { $0.absoluteString }.joined(separator: ", ")
            if !imageDescriptions.isEmpty {
                messages.append(PerplexityChatMessage(role: "user", content: .text("[Image URLs: \(imageDescriptions)]")))
            }
        }
        
        return messages
    }
} 
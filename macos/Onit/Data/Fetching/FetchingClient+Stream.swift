//
//  FetchingClient+Stream.swift
//  Onit
//

import Foundation

protocol StreamingEndpoint: Endpoint {
    associatedtype StreamResponse: Codable
    func processStreamResponse(_ response: StreamResponse) -> String?
}

extension OpenAIChatEndpoint: StreamingEndpoint {
    typealias StreamResponse = OpenAIChatResponse
    
    func processStreamResponse(_ response: OpenAIChatResponse) -> String? {
        response.choices.first?.delta.content
    }
}

extension AnthropicChatEndpoint: StreamingEndpoint {
    typealias StreamResponse = AnthropicChatResponse
    
    func processStreamResponse(_ response: AnthropicChatResponse) -> String? {
        if response.type == "content_block_delta" {
            return response.delta?.text
        }
        return nil
    }
}

extension XAIChatEndpoint: StreamingEndpoint {
    typealias StreamResponse = XAIChatResponse
    
    func processStreamResponse(_ response: XAIChatResponse) -> String? {
        response.choices.first?.delta.content
    }
}

extension FetchingClient {
    func executeStream<E: StreamingEndpoint>(
        _ endpoint: E,
        onReceive: @escaping @Sendable (String) async -> Void,
        onComplete: @escaping @Sendable () async -> Void
    ) async throws {
        try await executeSSE(endpoint, onEvent: { response in
            if let anthropicResponse = response as? AnthropicChatResponse, anthropicResponse.type == "content_block_delta" {
                if let text = anthropicResponse.delta?.text {
                    Task {
                        await onReceive(text)
                    }
                }
                if let stop = anthropicResponse.delta?.stopReason {
                    Task {
                        await onComplete()
                    }
                }
            }
            print(response)
        }, onError: { error in
//            throw FetchingError.httpError(statusCode: 500)
            print("Error:", error)
        })
        
//        let streamResponse = response.processStreamResponse(response)
        
        
//        _ = try await FetchingClient().execute(endpoint)
        
//        let (result, response) = try await session.bytes(for: request)
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw FetchingError.invalidResponse
//        }
//        
//        guard (200...299).contains(httpResponse.statusCode) else {
//            throw FetchingError.httpError(statusCode: httpResponse.statusCode)
//        }
//        
//        for try await line in result.lines {
//            guard !line.isEmpty else { continue }
//            guard line != "[DONE]" else { break }
//            
//            // Remove "data: " prefix if present
//            let jsonLine = line.hasPrefix("data: ") ? String(line.dropFirst(6)) : line
//            
//            do {
//                let streamResponse = try decoder.decode(E.StreamResponse.self, from: jsonLine.data(using: .utf8)!)
//                if let content = endpoint.processStreamResponse(streamResponse) {
//                    onReceive(content)
//                }
//            } catch {
//                print("Error decoding stream response:", error)
//                print("Line:", jsonLine)
//            }
//        }
//        
//        onComplete()
    }
}

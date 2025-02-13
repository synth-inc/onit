//
//  TypeaheadTest.swift
//  Onit
//
//  Created by Kévin Naudin on 04/03/2025.
//

struct TypeaheadTests: Codable {
    let version: String
    let tests: [TypeaheadTest]
}

struct TypeaheadTest: Codable {
    let id: String
    let systemMessage: String
    let userMessage: String
    let parameters: [String: String]
    
    struct Parameter {
        static let keepAlive = "keep_alive"
        static let numCtx = "num_ctx"
        static let temperature = "temperature"
        static let topK = "top_k"
        static let topP = "top_p"
    }
    
    struct Message {
        static let applicationName = "[APPLICATION_NAME]"
        static let applicationTitle = "[APPLICATION_TITLE]"
        static let screenContent = "[SCREEN_CONTENT]"
        static let precedingText = "[PRECEDING_TEXT]"
        static let followingText = "[FOLLOWING_TEXT]"
        static let fullText = "[FULL_TEXT]"
    }
}

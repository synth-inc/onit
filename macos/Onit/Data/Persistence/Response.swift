//
//  Response.swift
//  Onit
//
//  Created by Benjamin Sage on 11/2/24.
//

import Foundation
import SwiftData

@Model
class Response {
    var text: String
    var instruction: String?
    var timestamp: Date
    var type: ResponseType
    var model: String?

    // Tool call properties
    var toolCallName: String?
    var toolCallArguments: String?
    var toolCallResult: String?
    var toolCallSuccess: Bool?

    init(text: String, instruction: String?, type: ResponseType, model: String, time: Date = .now) {
        self.text = text
        self.instruction = instruction
        self.timestamp = time
        self.type = type
        self.model = model
    }
    
    static var partial: Response {
        .init(text: "", instruction: "", type: .partial, model: "")
    }
    
    var isPartial: Bool {
        type == .partial
    }

    var hasToolCall: Bool {
        toolCallName?.isEmpty == false
    }
}

enum ResponseType: String, Codable {
    case partial
    case success
    case error
}

// MARK: - Diff tool

extension Response {
    var isDiffResponse: Bool {
        return toolCallFunctionName?.hasPrefix("diff_") == true
    }
    
    var diffArguments: DiffTool.PlainTextDiffArguments? {
        guard let argumentsData = toolCallArguments?.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(DiffTool.PlainTextDiffArguments.self, from: argumentsData)
    }
    
    var diffResult: DiffTool.PlainTextDiffResult? {
        guard let resultData = toolCallResult?.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(DiffTool.PlainTextDiffResult.self, from: resultData)
    }
}

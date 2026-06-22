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

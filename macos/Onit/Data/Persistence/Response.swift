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
}

enum ResponseType: String, Codable {
    case partial
    case success
    case error
}

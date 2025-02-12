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
    var timestamp: Date
    var type: ResponseType

    init(text: String, type: ResponseType, time: Date = .now) {
        self.text = text
        self.timestamp = time
        self.type = type
    }
    
    static var partial: Response {
        .init(text: "", type: .partial)
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

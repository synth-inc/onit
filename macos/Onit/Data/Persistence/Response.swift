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
    //    var prompt: Prompt?

    init(text: String, type: ResponseType, time: Date = .now) {  // , prompt: Prompt? = nil) {
        self.text = text
        self.timestamp = time
        self.type = type
    }
}

enum ResponseType: String, Codable {
    case success
    case error
}

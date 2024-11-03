//
//  Response.swift
//  Onit
//
//  Created by Benjamin Sage on 11/2/24.
//

import SwiftData

@Model
class Response {
    var text: String
    var timestamp: String
    var prompt: Prompt?

    init(text: String, timestamp: String, prompt: Prompt? = nil) {
        self.text = text
        self.timestamp = timestamp
        self.prompt = prompt
    }
}

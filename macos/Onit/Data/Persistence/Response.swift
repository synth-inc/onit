//
//  Response.swift
//  Onit
//
//  Created by Benjamin Sage on 11/2/24.
//

import SwiftData
import Foundation

@Model
class Response {
    var text: String
    var timestamp: Date
//    var prompt: Prompt?

    init(text: String, time: Date = .now) { // , prompt: Prompt? = nil) {
        self.text = text
        self.timestamp = time
//        self.prompt = prompt
    }
}

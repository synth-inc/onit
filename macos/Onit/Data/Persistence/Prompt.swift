//
//  Prompt.swift
//  Onit
//
//  Created by Benjamin Sage on 10/27/24.
//

import Foundation
import SwiftData

@Model final class Prompt: Identifiable {
    var input: Input?
    var text: String
    var timestamp: Date
    @Relationship(deleteRule: .cascade, inverse: \Response.prompt)
    var responses: [Response] = []

    init(input: Input? = nil, text: String, timestamp: Date, responses: [Response] = []) {
        self.input = input
        self.text = text
        self.timestamp = timestamp
        self.responses = responses
    }
}

extension Prompt {
    @MainActor static let sample = Prompt(text: "Hello, world!", timestamp: .now)
}

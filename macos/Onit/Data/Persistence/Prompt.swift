//
//  Prompt.swift
//  Onit
//
//  Created by Benjamin Sage on 10/27/24.
//

import Foundation
import SwiftData

@Model final class Prompt {
    var input: Input?
    var text: String
    var timestamp: Date

    init(input: Input? = nil, text: String, timestamp: Date) {
        self.input = input
        self.text = text
        self.timestamp = timestamp
    }
}

extension Prompt {
    @MainActor static let sample = Prompt(text: "Hello, world!", timestamp: .now)
}

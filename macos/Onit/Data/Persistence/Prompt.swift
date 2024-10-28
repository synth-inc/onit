//
//  Prompt.swift
//  Onit
//
//  Created by Benjamin Sage on 10/27/24.
//

import SwiftData

@Model final class Prompt {
    var input: Input?
    var text: String

    init(input: Input? = nil, text: String) {
        self.input = input
        self.text = text
    }
}

extension Prompt {
    @MainActor static let sample = Prompt(text: "Hello, world!")
}

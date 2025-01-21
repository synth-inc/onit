//
//  Tooltip.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI
import KeyboardShortcuts

struct Tooltip {
    var prompt: String
    var shortcut: Shortcut

    enum Shortcut {
        case keyboardShortcuts(KeyboardShortcuts.Name)
        case none
    }

    init(prompt: String, shortcut: Shortcut = .none) {
        self.prompt = prompt
        self.shortcut = shortcut
    }

    init(prompt: String, shortcut: KeyboardShortcuts.Name) {
        self.prompt = prompt
        self.shortcut = .keyboardShortcuts(shortcut)
    }
}

extension Tooltip {
    static let sample = Tooltip(
        prompt: "Settings",
        shortcut: .keyboardShortcuts(.escape)
    )
}

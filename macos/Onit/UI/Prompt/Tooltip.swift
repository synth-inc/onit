//
//  Tooltip.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct Tooltip {
    var prompt: String
    var shortcut: Shortcut

    enum Shortcut {
        case keyboard(KeyboardShortcut)
        case text(String)
        case none
    }

    init(prompt: String, shortcut: Shortcut = .none) {
        self.prompt = prompt
        self.shortcut = shortcut
    }

    init(prompt: String, shortcut: KeyboardShortcut) {
        self.prompt = prompt
        self.shortcut = .keyboard(shortcut)
    }
}

extension Tooltip {
    static let sample = Tooltip(
        prompt: "Settings",
        shortcut: .init("K", modifiers: .command)
    )
}

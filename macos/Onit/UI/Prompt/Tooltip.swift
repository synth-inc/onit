//
//  Tooltip.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct Tooltip {
    var prompt: String
    var shortcut: KeyboardShortcut
}

extension Tooltip {
    static let sample = Tooltip(
        prompt: "Settings",
        shortcut: .init("K", modifiers: .command)
    )
}

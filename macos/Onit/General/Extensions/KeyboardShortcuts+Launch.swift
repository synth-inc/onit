//
//  KeyboardShortcuts+Launch.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let launch = KeyboardShortcuts.Name(
        .launch,
        default: .init(.space, modifiers: [.command, .option, .control])
    )
    static let escape = KeyboardShortcuts.Name(
        .escape,
        default: .init(.escape))
}

extension String {
    static let launch = "launch"
    static let escape = "escape"
}

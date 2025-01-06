//
//  KeyboardShortcuts+Launch.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let launch = Self("launch", default: .init(.o, modifiers: [.command]))
    static let launchIncognito = Self("launchIncognito", default: .init(.o, modifiers: [.command, .shift]))
    static let escape = Self("escape", default: .init(.escape))
}

extension String {
    static let launch = "launch"
    static let launchIncognito = "launchIncognit"
    static let escape = "escape"
}

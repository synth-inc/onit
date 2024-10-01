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
}

extension String {
    static let launch = "launch"
}

extension KeyboardShortcuts {
    static func launch() {
        KeyboardShortcuts.onKeyUp(for: .launch) {
            if let url = URL(string: "onit://" + .launch) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

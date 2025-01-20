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
    static let escape = Self("escape", default: .init(.escape))
    static let openSettings = Self("openSettings", default: .init(.comma, modifiers: [.command]))
    static let newChat = Self("newChat", default: .init(.n, modifiers: [.command]))
    static let resizeWindow = Self("resizeWindow", default: .init(.r, modifiers: [.command]))
    static let toggleModels = Self("toggleModels", default: .init(.m, modifiers: [.command]))
    static let openLocalMode = Self("openLocalMode", default: .init(.l, modifiers: [.command]))
}

extension String {
    static let launch = "launch"
    static let escape = "escape"
    static let openSettings = "openSettings"
    static let newChat = "newChat"
    static let resizeWindow = "resizeWindow"
    static let toggleModels = "toggleModels"
    static let openLocalMode = "openLocalMode"
}

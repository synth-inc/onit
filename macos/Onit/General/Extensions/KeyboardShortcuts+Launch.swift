//
//  KeyboardShortcuts+Launch.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let launch = Self("launch", default: .init(.zero, modifiers: [.command]))
    static let escape = Self("escape", default: .init(.escape))
    static let enter = Self("enter", default: .init(.return, modifiers: []))
    static let newChat = Self("newChat", default: .init(.n, modifiers: [.command]))
    static let resizeWindow = Self("resizeWindow", default: .init(.o, modifiers: [.command]))
    static let toggleModels = Self("toggleModels", default: .init(.t, modifiers: [.command]))
    static let toggleLocalMode = Self("toggleLocalMode", default: .init(.zero, modifiers: [.shift, .command]))
}

extension String {
    static let launch = "launch"
    static let escape = "escape"
    static let newChat = "newChat"
    static let resizeWindow = "resizeWindow"
    static let toggleModels = "toggleModels"
    static let toggleLocalMode = "toggleLocalMode"
}

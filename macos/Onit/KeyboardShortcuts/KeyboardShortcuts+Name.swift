//
//  KeyboardShortcuts+Name.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let launch = Self("launch", default: .init(.zero, modifiers: [.command]))
    static let launchWithAutoContext = Self(
        "launchWithAutoContext", default: .init(.zero, modifiers: [.shift, .command]))
    static let escape = Self("escape", default: .init(.escape))
    static let enter = Self("enter", default: .init(.return, modifiers: []))
    static let newChat = Self("newChat", default: .init(.nine, modifiers: [.command]))
    static let toggleLocalMode = Self(
        "toggleLocalMode", default: .init(.seven, modifiers: [.shift, .command]))
    static let addForegroundWindowToContext = Self(
        "addForegroundWindowToContext", default: .init(.w, modifiers: [.shift, .command]))
    static let quickEdit = Self("quickEdit", default: .init(.k, modifiers: [.command]))
    
    @MainActor
    var shortcutText: String {
        guard let shortcut = self.shortcut?.native else { return "" }
        
        var result = ""
        
        if shortcut.modifiers.contains(.option) { result += "⌥" }
        if shortcut.modifiers.contains(.shift) { result += "⇧" }
        if shortcut.modifiers.contains(.control) { result += "^" }
        if shortcut.modifiers.contains(.command) { result += "⌘" }
        
        switch shortcut.key {
        case .return:
            result += "⏎"
        case .delete:
            result += "⌫"
        case .space:
            result += "␣"
        case .escape:
            result += "ESC"
        default:
            result += String(shortcut.key.character).uppercased()
        }
        
        return result
    }
}

extension KeyboardShortcuts.Name: @retroactive CaseIterable {
    public static let allCases: [Self] = [
        .launch,
        .launchWithAutoContext,
        .escape,
        .newChat,
        .toggleLocalMode,
        .addForegroundWindowToContext,
        .quickEdit
    ]
}

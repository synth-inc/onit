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

    // Remapped key consumer - consumes events on the remapped Caps Lock key (currently F18)
    static let remappedKeyConsumer = Self("remappedKeyConsumer", default: .init(.f18, modifiers: []))
    // Shift + remapped key consumer (Shift + Caps Lock)
    static let remappedKeyConsumerShifted = Self("remappedKeyConsumerShifted", default: .init(.f18, modifiers: [.shift]))
    private func formatFunctionRowText() -> String {
        guard let shortcutKey = self.shortcut?.key else { return "" }
        
        switch shortcutKey {
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .f13: return "F13"
        case .f14: return "F14"
        case .f15: return "F15"
        case .f16: return "F16"
        case .f17: return "F17"
        case .f18: return "F18"
        case .f19: return "F19"
        case .f20: return "F20"
        default: return ""
        }
    }
    
    @MainActor
    var shortcutText: String {
        guard let shortcut = self.shortcut?.native else { return "" }
        
        var result = ""
        
        if shortcut.modifiers.contains(.option) { result += "⌥" }
        if shortcut.modifiers.contains(.control) { result += "^" }
        if shortcut.modifiers.contains(.command) { result += "⌘" }
        if shortcut.modifiers.contains(.shift) { result += "⇧" }
        
        switch shortcut.key {
        case .return:
            result += "⏎"
        case .delete:
            result += "⌫"
        case .space:
            result += "␣"
        case .escape:
            result += "ESC"
        case .tab:
            result += "⇥"
        case .upArrow:
            result += "↑"
        case .downArrow:
            result += "↓"
        case .rightArrow:
            result += "→"
        default:
            let shortcutKey = String(shortcut.key.character).uppercased()
            
            /// For some reason, the function row keys get registered only as "F", rather than "F18", "F19", etc.
            /// `self.formatFunctionRowText()` makes sure to show the proper string.
            if shortcutKey == "F" {
                result += self.formatFunctionRowText()
            } else {
                result += shortcutKey
            }
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
        .remappedKeyConsumer,
    ]
}

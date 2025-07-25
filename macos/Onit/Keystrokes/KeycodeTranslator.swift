//
//  KeycodeTranslator.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/24/25.
//

import Foundation
import AppKit

@MainActor
final class KeyCodeTranslator {
    static let shared = KeyCodeTranslator()

    private let keyCodeMap: [Int64: String] = [
        // Letters
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
        11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
        39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".",
        50: "`",

        // Numbers
        82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",

        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
        106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",

        // Special keys
        36: "return", 48: "tab", 49: "space", 51: "delete", 53: "escape",
        76: "enter", 117: "forward_delete", 119: "end", 115: "home",
        116: "page_up", 121: "page_down", 123: "left", 124: "right", 125: "down", 126: "up",

        // Keypad
        65: "keypad_.", 67: "keypad_*", 69: "keypad_+", 71: "keypad_clear", 75: "keypad_/",
        78: "keypad_-", 81: "keypad_=",

        // Other
        114: "help", 72: "volume_up", 73: "volume_down", 74: "mute"
    ]

    private let shiftedKeyMap: [Int64: String] = [
        // Shifted letters become uppercase automatically
        // Shifted numbers and symbols
        18: "!", 19: "@", 20: "#", 21: "$", 23: "%", 22: "^", 26: "&", 28: "*", 25: "(", 29: ")",
        27: "_", 24: "+", 33: "{", 30: "}", 42: "|", 41: ":", 39: "\"", 43: "<", 47: ">", 44: "?",
        50: "~"
    ]

    private init() {}

    func translateKeyCode(_ keyCode: Int64,
                         isShiftPressed: Bool = false,
                         isCommandPressed: Bool = false,
                         isControlPressed: Bool = false,
                         isOptionPressed: Bool = false) -> String {

        var modifiers: [String] = []
        if isControlPressed { modifiers.append("ctrl") }
        if isOptionPressed { modifiers.append("opt") }
        if isCommandPressed { modifiers.append("cmd") }

        // Only add shift to modifiers if it doesn't naturally transform the character
        // (we'll determine this after processing the key)

        var keyString: String

        // Handle shifted characters
        let hasNaturalShiftTransformation: Bool
        if isShiftPressed {
            if let shiftedChar = shiftedKeyMap[keyCode] {
                keyString = shiftedChar
                hasNaturalShiftTransformation = true // shift produces a different character naturally
            } else if let normalChar = keyCodeMap[keyCode] {
                // For letters, make them uppercase when shift is pressed
                if normalChar.count == 1 && normalChar.first!.isLetter {
                    keyString = normalChar.uppercased()
                    hasNaturalShiftTransformation = true // shift produces uppercase naturally
                } else {
                    keyString = normalChar
                    hasNaturalShiftTransformation = false // shift doesn't change the character
                }
            } else {
                keyString = "unknown(\(keyCode))"
                hasNaturalShiftTransformation = false
            }
        } else {
            keyString = keyCodeMap[keyCode] ?? "unknown(\(keyCode))"
            hasNaturalShiftTransformation = false
        }

        // Add shift to modifiers only if it doesn't naturally transform the character
        if isShiftPressed && !hasNaturalShiftTransformation {
            modifiers.append("shift")
        }

        // Combine modifiers with the key
        if modifiers.isEmpty {
            return keyString
        } else {
            return modifiers.joined(separator: "+") + "+" + keyString
        }
    }

    // Determines if a key combination modifies text field contents (adds or removes characters)
    func keyProducesOutput(_ keyCode: Int64,
                          isShiftPressed: Bool = false,
                          isCommandPressed: Bool = false,
                          isControlPressed: Bool = false,
                          isOptionPressed: Bool = false) -> Bool {

        // Keys that never modify text field contents regardless of modifiers
        let nonOutputKeys: Set<Int64> = [
            // Arrow keys
            123, 124, 125, 126, // left, right, down, up

            // Function keys
            122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, // F1-F12
            105, 107, 113, 106, 64, 79, 80, 90, // F13-F20

            // Navigation keys (cursor movement only)
            119, 115, 116, 121, // end, home, page_up, page_down
            53, // escape
            114, // help

            // Volume controls
            72, 73, 74, // volume_up, volume_down, mute

            // Keypad operations (these perform actions rather than insert characters)
            67, 69, 71, 75, 78, 81 // keypad_*, keypad_+, keypad_clear, keypad_/, keypad_-, keypad_=
        ]

        // If it's a non-output key, it never produces output
        if nonOutputKeys.contains(keyCode) {
            return false
        }

        // Keys that produce output or modify text field contents
        let outputKeys: Set<Int64> = [
            // Letters
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, // a-t
            31, 32, 34, 35, 37, 38, 40, 45, 46, // o, u, i, p, l, j, k, n, m

            // Numbers (main keyboard)
            18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, // 1-0 and symbols

            // Numbers (keypad)
            82, 83, 84, 85, 86, 87, 88, 89, 91, 92, // keypad 0-9
            65, // keypad decimal point

            // Symbols and punctuation
            33, 39, 41, 42, 43, 44, 47, 50, // [, ', ;, \, ,, /, ., `

            // Special output keys
            36, 48, 49, 76, // return, tab, space, enter

            // Delete keys (modify text field by removing characters)
            51, 117 // delete, forward_delete
        ]

        // If it's a known output key, check for modifier restrictions
        if outputKeys.contains(keyCode) {
            // Command combinations: some DO modify text content (cut, paste, undo, etc.)
            if isCommandPressed {
                // Command keys that modify text content
                let textModifyingCommandKeys: Set<Int64> = [
                    9, // v - paste (adds text from clipboard)
                    7, // x - cut (removes selected text)
                    6, // z - undo (can add or remove text)
                    16, // y - redo (can add or remove text, if app uses Cmd+Y for redo)
                    0, // a - select all (when followed by typing, replaces all text)
                ]

                // Handle Cmd+Shift+Z for redo (more common than Cmd+Y)
                if isShiftPressed && keyCode == 6 { // z
                    return true
                }

                return textModifyingCommandKeys.contains(keyCode)
            }

            // Control combinations: many DO modify text content in macOS (Emacs-style bindings)
            if isControlPressed {
                // Control keys that modify text content (based on macOS default Emacs bindings)
                let textModifyingControlKeys: Set<Int64> = [
                    4, // h - delete character to left (like backspace)
                    2, // d - delete character to right (like forward delete)
                    40, // k - delete from cursor to end of line
                    32, // u - delete from cursor to beginning of line (if supported)
                    13, // w - delete word backward (if supported)
                    17, // t - transpose characters
                    31, // o - insert new line
                    16, // y - yank from kill buffer
                    // Delete keys work with Control too
                    51, 117 // delete, forward_delete
                ]

                return textModifyingControlKeys.contains(keyCode)
            }

            // Shift and Option with output keys still produce output (shifted chars, accented chars)
            return true
        }

        // For unknown keys, assume they don't modify text field contents
        return false
    }

    // Convenience method for when you have all the modifier states
    func translateKeyCodeWithModifiers(_ keyCode: Int64,
                                     modifierStates: (command: Bool, control: Bool, shift: Bool, option: Bool)) -> String {
        return translateKeyCode(keyCode,
                              isShiftPressed: modifierStates.shift,
                              isCommandPressed: modifierStates.command,
                              isControlPressed: modifierStates.control,
                              isOptionPressed: modifierStates.option)
    }

    // Convenience method for when you have all the modifier states
    func keyProducesOutputWithModifiers(_ keyCode: Int64,
                                       modifierStates: (command: Bool, control: Bool, shift: Bool, option: Bool)) -> Bool {
        return keyProducesOutput(keyCode,
                               isShiftPressed: modifierStates.shift,
                               isCommandPressed: modifierStates.command,
                               isControlPressed: modifierStates.control,
                               isOptionPressed: modifierStates.option)
    }

    /// Converts a key name string to its actual character representation for keystroke tracking
    /// This is used to convert strings like "space", "tab", etc. back to their actual characters
    func keyNameToCharacter(_ keyName: String) -> String {
        switch keyName {
        case "space":
            return " "
        case "tab":
            return "\t"
        case "return", "enter":
            return "\n"
        default:
            // For everything else, return as-is (letters, numbers, symbols)
            return keyName
        }
    }

    /// Converts an array of keystroke strings to actual characters for text comparison
    /// This joins keystrokes and converts special key names to their character equivalents
    func keystrokesToText(_ keystrokes: [String]) -> String {
        return keystrokes.map { keyNameToCharacter($0) }.joined()
    }
}

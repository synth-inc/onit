//
//  KeyboardShortcuts+Native.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import KeyboardShortcuts
import SwiftUI
import AppKit
import Carbon

extension KeyboardShortcuts.Shortcut {
    @available(macOS 11, *)
    @MainActor
    var native: KeyboardShortcut? {
        guard let characterString = self.character, let character = characterString.first else {
            return nil
        }

        return KeyboardShortcut(.init(character), modifiers: self.swiftUIModifiers)
    }

    /// Convert Carbon modifiers to SwiftUI `EventModifiers`.
    private var swiftUIModifiers: SwiftUI.EventModifiers {
        var result: SwiftUI.EventModifiers = []

        if modifiers.contains(.command) {
            result.insert(.command)
        }
        if modifiers.contains(.option) {
            result.insert(.option)
        }
        if modifiers.contains(.shift) {
            result.insert(.shift)
        }
        if modifiers.contains(.control) {
            result.insert(.control)
        }

        return result
    }

    /// Retrieve the character representation for the key, if available.
    private var character: String? {
        if let key = key, let mappedCharacter = Self.keyToCharacterMapping[key] {
            return mappedCharacter
        }

        // For other keys, we use CoreServices to translate the keycode
        guard
            let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
            let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }

        let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
        let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
        var deadKeyState: UInt32 = 0
        let maxLength = 4
        var length = 0
        var characters = [UniChar](repeating: 0, count: maxLength)

        let error = UCKeyTranslate(
            keyLayout,
            UInt16(carbonKeyCode),
            UInt16(kUCKeyActionDisplay),
            0, // No modifiers
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxLength,
            &length,
            &characters
        )

        guard error == noErr else {
            return nil
        }

        return String(utf16CodeUnits: characters, count: length)
    }

    /// Key to character mapping for common keys.
    private static let keyToCharacterMapping: [KeyboardShortcuts.Key: String] = [
        .return: "↩",
        .delete: "⌫",
        .deleteForward: "⌦",
        .end: "↘",
        .escape: "⎋",
        .help: "?⃝",
        .home: "↖",
        .space: " ",
        .tab: "⇥",
        .pageUp: "⇞",
        .pageDown: "⇟",
        .upArrow: "↑",
        .rightArrow: "→",
        .downArrow: "↓",
        .leftArrow: "←",
        .f1: "F1",
        .f2: "F2",
        .f3: "F3",
        .f4: "F4",
        .f5: "F5",
        .f6: "F6",
        .f7: "F7",
        .f8: "F8",
        .f9: "F9",
        .f10: "F10",
        .f11: "F11",
        .f12: "F12",
        .f13: "F13",
        .f14: "F14",
        .f15: "F15",
        .f16: "F16",
        .f17: "F17",
        .f18: "F18",
        .f19: "F19",
        .f20: "F20",
        .keypad0: "0\u{20e3}",
        .keypad1: "1\u{20e3}",
        .keypad2: "2\u{20e3}",
        .keypad3: "3\u{20e3}",
        .keypad4: "4\u{20e3}",
        .keypad5: "5\u{20e3}",
        .keypad6: "6\u{20e3}",
        .keypad7: "7\u{20e3}",
        .keypad8: "8\u{20e3}",
        .keypad9: "9\u{20e3}",
        .keypadClear: "☒\u{20e3}",
        .keypadDecimal: ".\u{20e3}",
        .keypadDivide: "/\u{20e3}",
        .keypadEnter: "↩\u{20e3}",
        .keypadEquals: "=\u{20e3}",
        .keypadMinus: "-\u{20e3}",
        .keypadMultiply: "*\u{20e3}",
        .keypadPlus: "+\u{20e3}"
    ]
}

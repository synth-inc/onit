//
//  MenuBarOpenPanel.swift
//  Onit
//
//  Created by Loyd Kim on 9/25/25.
//

import AppKit
import Carbon
import KeyboardShortcuts

final class MenuBarOpenPanel: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""

        if let icon = NSImage(named: "noodle")?.copy() as? NSImage {
            icon.size = NSSize(width: 11, height: 11)
            self.image = icon
        }

        self.action = #selector(launchPanel)
        self.keyEquivalent = ""
        self.keyEquivalentModifierMask = []
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized(" Open Onit", table: "MenuBar")
        self.updateKeyEquivalentFromKeyboardShortcut()
    }

    // MARK: - Private Variables

    let modifiers: [NSEvent.ModifierFlags] = [
        .command,
        .option,
        .shift,
        .control
    ]

    // MARK: - Private Functions

    @MainActor
    private func updateKeyEquivalentFromKeyboardShortcut() {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .launchWithAutoContext)
        else {
            self.keyEquivalent = ""
            self.keyEquivalentModifierMask = []
            return
        }

        if let key = shortcut.native?.key {
            self.keyEquivalent = String(key.character).lowercased()
        } else {
            self.keyEquivalent = ""
        }

        self.keyEquivalentModifierMask = self.getModifierFlagsFromKeyboardShortcut(shortcut)
    }

    private func getModifierFlagsFromKeyboardShortcut(_ shortcut: KeyboardShortcuts.Shortcut) -> NSEvent.ModifierFlags {
        var modifierFlags: NSEvent.ModifierFlags = []

        for modifier in self.modifiers {
            if shortcut.modifiers.contains(modifier) {
                modifierFlags.insert(modifier)
            }
        }

        return modifierFlags
    }

    @MainActor
    @objc private func launchPanel() {
        PanelStateCoordinator.shared.launchPanel()
    }
}

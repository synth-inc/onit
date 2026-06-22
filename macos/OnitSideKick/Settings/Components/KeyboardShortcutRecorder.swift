//
//  KeyboardShortcutRecorder.swift
//  Onit
//
//  Created by Loyd Kim on 10/31/25.
//

import KeyboardShortcuts
import SwiftUI

struct KeyboardShortcutRecorder: View {
    // MARK: - Properties
    
    private let shortcutName: KeyboardShortcuts.Name
    private let previousShortcut: KeyboardShortcuts.Shortcut?
    private let onUpdate: (() -> Void)?
    
    // MARK: - Initializer
    
    init(
        shortcutName: KeyboardShortcuts.Name,
        previousShortcut: KeyboardShortcuts.Shortcut? = nil,
        onUpdate: (() -> Void)? = nil
    ) {
        self.shortcutName = shortcutName
        self.previousShortcut = previousShortcut
        self.onUpdate = onUpdate
    }
    
    // MARK: - Body
    
    var body: some View {
        KeyboardShortcuts.Recorder(for: shortcutName) { newShortcut in
            /// This prevents setting empty shortcuts.
            if newShortcut == nil {
                KeyboardShortcutsManager.resetKeyboardShortcut(
                    for: shortcutName,
                    to: self.previousShortcut
                )
            } else {
                self.onUpdate?()
            }
        }
    }
}

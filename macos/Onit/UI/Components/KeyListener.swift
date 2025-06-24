//
//  KeyListener.swift
//  Onit
//
//  Created by Loyd Kim on 6/10/25.
//

import SwiftUI

struct KeyListener: View {
    private let key: KeyEquivalent
    private let modifiers: EventModifiers
    private let action: () -> Void
    
    init(
        key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        action: @escaping () -> Void
    ) {
        self.key = key
        self.modifiers = modifiers
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            EmptyView()
        }
        .opacity(0)
        .allowsHitTesting(false)
        .keyboardShortcut(key, modifiers: modifiers)
    }
}

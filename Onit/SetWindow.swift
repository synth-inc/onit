//
//  SetWindow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import AppKit

func setWindow(_ id: String, transform: (NSWindow) -> Void) {
    for window in NSApplication.shared.windows {
        if window.identifier == NSUserInterfaceItemIdentifier(id) {
            transform(window)
        }
    }
}

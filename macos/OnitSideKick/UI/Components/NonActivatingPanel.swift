//
//  NonActivatingPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 09/05/2025.
//

import AppKit

class NonActivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    func setup(
        delegate: NSWindowDelegate? = nil,
        addShadow: Bool = true,
        clickThrough: Bool = false
    ) {
        styleMask = [.nonactivatingPanel, .borderless]
        isOpaque = false
        backgroundColor = NSColor.clear
        level = .screenSaver
        hasShadow = addShadow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        isReleasedWhenClosed = false
        ignoresMouseEvents = clickThrough
        hidesOnDeactivate = false
        self.delegate = delegate
    }
}

//
//  PanelStateConventionalManager+Display.swift
//  Onit
//
//  Created by Codex on 2024-06-01.
//

import AppKit
import Defaults

extension PanelStateConventionalManager {
    func showPanel(for state: OnitPanelState) {
        guard let panel = state.panel else { return }

        panel.makeKeyAndOrderFront(nil)

        var targetFrame: NSRect?
        if let stored = Defaults[.conventionalPanelFrame], stored.findScreen() != nil {
            targetFrame = stored
        } else if let screen = NSScreen.mouse {
            targetFrame = NSRect(
                x: screen.visibleFrame.maxX - state.panelWidth,
                y: screen.visibleFrame.minY,
                width: state.panelWidth,
                height: screen.visibleFrame.height
            )
        }

        if let frame = targetFrame {
            panel.setFrame(frame, display: true)
        }
    }

    func hidePanel(for state: OnitPanelState) {
        guard let panel = state.panel else { return }
        panel.hide()
        state.panel = nil
        if let screen = NSScreen.mouse {
            debouncedShowTetherWindow(activeScreen: screen)
        }
    }
}

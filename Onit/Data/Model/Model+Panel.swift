//
//  Model+Panel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

extension Model: NSWindowDelegate {
    func showPanel() {
        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            existingPanel.orderFrontRegardless()
            return
        }

        let newPanel = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        newPanel.isOpaque = false
        newPanel.backgroundColor = NSColor.clear
        newPanel.level = .floating
        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true
        newPanel.delegate = self

        newPanel.standardWindowButton(.closeButton)?.isHidden = true
        newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newPanel.standardWindowButton(.zoomButton)?.isHidden = true
        newPanel.isFloatingPanel = true

        let panelContentView = NSHostingView(rootView: ContentView().environment(self))
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        newPanel.contentView = panelContentView

        panel = newPanel

        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let windowHeight = newPanel.frame.height

            let xPosition = visibleFrame.origin.x + 16
            let yPosition = visibleFrame.origin.y + visibleFrame.height - 16 - windowHeight

            newPanel.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        }

        newPanel.makeKeyAndOrderFront(nil)
        newPanel.orderFrontRegardless()
    }

    func closePanel() {
        guard let panel = panel else { return }
        panel.orderOut(nil)
        self.panel = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        closePanel()
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
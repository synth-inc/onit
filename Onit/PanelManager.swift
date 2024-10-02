//
//  PanelManager.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Observation
import SwiftUI

@MainActor @Observable final class PanelManager: NSObject {
    private var panel: CustomPanel?

    func showPanel() {
        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
//            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newPanel = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .floating

        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true

        newPanel.standardWindowButton(.closeButton)?.isHidden = true
        newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newPanel.standardWindowButton(.zoomButton)?.isHidden = true

        let panelContentView = NSHostingView(rootView: ContentView(panelManager: self))
        newPanel.contentView = panelContentView

        self.panel = newPanel

//        newPanel.center()
        newPanel.makeKeyAndOrderFront(nil)
//        NSApp.activate(ignoringOtherApps: true)
    }

    func closePanel() {
        guard let panel = panel else { return }
        panel.orderOut(nil)
        self.panel = nil
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}

extension EnvironmentValues {
    var panelManager: PanelManager {
        get { self[PanelManagerEnvironmentKey.self] }
        set { self[PanelManagerEnvironmentKey.self] = newValue }
    }
}

@MainActor
struct PanelManagerEnvironmentKey: @preconcurrency EnvironmentKey {
    static let defaultValue: PanelManager = .init()
}

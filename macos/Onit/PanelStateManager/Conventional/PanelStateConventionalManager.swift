//
//  PanelStateConventionalManager.swift
//  Onit
//
//  Created by Codex on 2024-06-01.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class PanelStateConventionalManager: PanelStateBaseManager, ObservableObject {

    static let shared = PanelStateConventionalManager()

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var lastScreenFrame = CGRect.zero

    private override init() {
        super.init()
        states = []
    }

    override func start() {
        stop()

        let state = OnitPanelState()
        self.state = state
        states = [state]

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.activateMouseScreen()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.activateMouseScreen()
            return event
        }

        state.addDelegate(self)
        activateMouseScreen(forced: true)
    }

    override func stop() {
        if let global = globalMouseMonitor { NSEvent.removeMonitor(global); globalMouseMonitor = nil }
        if let local = localMouseMonitor { NSEvent.removeMonitor(local); localMouseMonitor = nil }
        lastScreenFrame = .zero
        state.removeDelegate(self)
        super.stop()
    }

    override func launchPanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.opened(displayMode: "conventional")
        buildPanelIfNeeded(for: state)
        showPanel(for: state)
    }

    override func closePanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.closed(displayMode: "conventional")
        if let frame = state.panel?.frame {
            Defaults[.conventionalPanelFrame] = frame
        }
        hidePanel(for: state)
        super.closePanel(for: state)
    }

    override func fetchWindowContext() { }

    func activateMouseScreen(forced: Bool = false) {
        if forced { lastScreenFrame = .zero }
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                handleActivation(of: mouseScreen)
                lastScreenFrame = mouseScreen.frame
            }
        }
    }

    private func handleActivation(of screen: NSScreen) {
        if state.panelOpened {
            hideTetherWindow()
        } else {
            debouncedShowTetherWindow(activeScreen: screen)
        }
    }
}

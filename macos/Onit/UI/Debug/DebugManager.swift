//
//  DebugManager.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import Defaults
import SwiftUI

@MainActor
class DebugManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DebugManager()
    
    // MARK: - Properties
    
    @Published var showDebugWindow = false
    @Published var debugText: String = ""
    var debugPanel: NSPanel? = nil
    
    // MARK: - Functions
    
    func openDebugWindow() {
        let debugPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 800),
            styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        debugPanel.isOpaque = false
        debugPanel.backgroundColor = NSColor.clear
        debugPanel.level = .floating
        debugPanel.titleVisibility = .hidden
        debugPanel.titlebarAppearsTransparent = true
        debugPanel.isMovableByWindowBackground = true
        //debugPanel.delegate = self

        debugPanel.standardWindowButton(.closeButton)?.isHidden = true
        debugPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        debugPanel.standardWindowButton(.zoomButton)?.isHidden = true
        debugPanel.isFloatingPanel = true

        let debugPanelContentView = NSHostingView(rootView: DebugView())
        debugPanelContentView.wantsLayer = true
        debugPanelContentView.layer?.cornerRadius = 14
        debugPanelContentView.layer?.cornerCurve = .continuous
        debugPanelContentView.layer?.masksToBounds = true
        debugPanelContentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        debugPanel.contentView = debugPanelContentView
        debugPanel.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))

//        if let screen = NSScreen.main {
//            let visibleFrame = screen.visibleFrame
//            let defaultPanelFrame = NSRect(x: 0, y: 0, width: 400, height: 600)
//            let windowWidth = defaultPanelFrame.width
//            let windowHeight = defaultPanelFrame.height
//
//            let finalXPosition = visibleFrame.origin.x + visibleFrame.width - 16 - windowWidth
//            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - 16 - ContentView.bottomPadding
//            debugPanel.setFrameOrigin(
//                NSPoint(x: finalXPosition, y: finalYPosition - (windowHeight * 2.0) - 16))
//            debugPanel.makeKeyAndOrderFront(nil)
//            debugPanel.orderFrontRegardless()
//        }

        debugPanel.makeKeyAndOrderFront(nil)
        debugPanel.orderFrontRegardless()
        
        self.debugPanel = debugPanel
    }

    func closeDebugWindow() {
        guard let panel = debugPanel else { return }
        
        panel.orderOut(nil)
        self.debugPanel = nil
    }
}

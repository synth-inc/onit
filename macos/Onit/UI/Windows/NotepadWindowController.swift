//
//  NotepadWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import AppKit
import SwiftUI

@MainActor
class NotepadWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Singleton
    
    static let shared = NotepadWindowController()

    // MARK: - Properties

    private var panel: NSPanel?

    // MARK: - Functions

    func showWindow(windowState: OnitPanelState, response: Response) {
        guard response.isDiffResponse,
              let _ = response.diffArguments,
              let _ = response.diffResult else {
            print("NotepadWindowController: Invalid diff response provided")
            return
        }
        
        let contentView = NotepadView(
            response: response,
            closeCompletion: closeWindow
        )
        .environment(\.windowState, windowState)
        
        let panelContentView = NSHostingView(rootView: contentView)
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = .black

        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
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
            
            panel = newPanel
        }
        
        panel?.contentView = panelContentView
        panel?.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        
        positionWindow(windowState: windowState)
        bringToFront()
    }

    func bringToFront() {
        panel?.alphaValue = 1.0
        panel?.orderFront(nil)
    }

    func closeWindow() {
        guard let panel = panel else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
            },
            completionHandler: {
                panel.orderOut(nil)
                panel.alphaValue = 1.0
            })
    }

    // MARK: - Private Functions

    private func positionWindow(windowState: OnitPanelState) {
        guard let panel = self.panel,
              let onitPanel = windowState.panel else { return }

        var newFrame = onitPanel.frame
        
        newFrame.origin.x = onitPanel.frame.origin.x - onitPanel.frame.width + (TetheredButton.width / 2)

        panel.setFrame(newFrame, display: false, animate: false)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        
    }

}

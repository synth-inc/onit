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

    private weak var model: OnitModel?
    private var contentView: NotepadView?
    private var panel: NSPanel?
    
    @Published var prompt: Prompt?

    // MARK: - Initializers

    func configure(model: OnitModel) {
        self.model = model
        
        // Update content view initialization
        self.contentView = NotepadView(
            prompt: Binding(
                get: { [weak self] in self?.prompt },
                set: { [weak self] in self?.prompt = $0 }
            ),
            closeCompletion: closeWindow
        )

        let contentView = contentView
            .environment(\.model, model)

        let panelContentView = NSHostingView(rootView: contentView)
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = .black

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 0),
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
        
        newPanel.contentView = panelContentView
        newPanel.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        
        panel = newPanel
    }

    // MARK: - Functions

    func showWindow(prompt: Prompt) {
        self.prompt = prompt
        
        positionWindow()
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

    private func positionWindow() {
        guard let panel = self.panel,
              let onitPanel = model?.panel else { return }

        let mouseLocation = NSEvent.mouseLocation

        guard
            let screen = NSScreen.screens.first(where: {
                NSMouseInRect(mouseLocation, $0.frame, false)
            })
        else {
            print("No screen contains the mouse location.")
            return
        }

        let visibleFrame = screen.visibleFrame

        var newFrame = onitPanel.frame
        newFrame.origin.x = visibleFrame.width - (onitPanel.frame.width * 2)

        panel.setFrame(newFrame, display: false, animate: false)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        
    }

}

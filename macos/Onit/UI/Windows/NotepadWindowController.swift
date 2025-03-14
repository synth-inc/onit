//
//  NotepadWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import AppKit
import SwiftUI

class NotepadConfig: ObservableObject {
    @Published var oldText: String
    @Published var newText: String
    @Published var isStreaming: Bool
    
    init(oldText: String = "", newText: String = "", isStreaming: Bool = false) {
        self.oldText = oldText
        self.newText = newText
        self.isStreaming = isStreaming
    }
}

@MainActor
class NotepadWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Singleton
    
    static let shared = NotepadWindowController()

    // MARK: - Properties

    private weak var model: OnitModel?
    private var contentView: NotepadView?
    private var panel: NSPanel?
    
    @Published private var config = NotepadConfig()
    
//    private var oldText: String {
//        guard let prompt = prompt else { return "" }
//        
//        let autoContexts = prompt.contextList.autoContexts
//        
//        if let input = prompt.input {
//            print("NotepadView oldText : \(input.selectedText)")
//            return input.selectedText
//        } else if !autoContexts.isEmpty {
//            print("NotepadView oldText : \(autoContexts.values.joined(separator: "\n"))")
//            return autoContexts.values.joined(separator: "\n")
//        }
//        
//        return ""
//    }
//    private var newText: String {
//        guard let prompt = prompt else { return "" }
//        
//        let response = prompt.responses[prompt.generationIndex]
//        
//        print("NotepadView newText : \(response.isPartial ? model.streamedResponse : response.text)")
//        
//        return response.isPartial ? model.streamedResponse : response.text
//    }
//    private var isStreaming: Bool {
//        guard let prompt = prompt else {
//            return false
//        }
//        
//        let response = prompt.responses[prompt.generationIndex]
//        
//        print("NotepadView isStreaming : \(response.isPartial)")
//        
//        return response.isPartial
//    }
    
    

    // MARK: - Initializers

    func configure(model: OnitModel) {
        self.model = model
        
        // Update content view initialization
        self.contentView = NotepadView(
            closeCompletion: closeWindow
        )

        let contentView = contentView
            .environment(\.model, model)
            .environmentObject(config)

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

    func showWindow(oldText: String, newText: String, isStreaming: Bool) {
        print("showWindow called - oldText: \(oldText.prefix(20))... newText: \(newText.prefix(20))... isStreaming: \(isStreaming)")
        config.oldText = oldText
        config.newText = newText
        config.isStreaming = isStreaming
        
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

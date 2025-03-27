//
//  OnitRegularPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 26/03/2025.
//

import Defaults
import SwiftUI

@MainActor
class OnitRegularPanel: NSPanel {
    
    override var canBecomeKey: Bool {
        return true
    }
    
    private let width = ContentView.idealWidth
    
    init(model: OnitModel) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 0),
            styleMask: [.titled, .closable, .miniaturizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        isOpaque = false
        backgroundColor = NSColor.clear
        level = .normal
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        delegate = model
        isFloatingPanel = false
        
        let contentView = ContentView()
            .modelContainer(model.container)
            .environment(model)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 14
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = .clear

        self.contentView = hostingView
        self.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        
        show()
    }
    
    private func setupFrame() {
        if let screen = findScreen() {
            let visibleFrame = screen.visibleFrame
            let windowHeight = frame.height
            
            let newFrame = NSRect(
                x: visibleFrame.origin.x + visibleFrame.width - width,
                y: visibleFrame.origin.y + visibleFrame.height - windowHeight,
                width: width,
                height: visibleFrame.height - visibleFrame.origin.y - ContentView.bottomPadding
            )
            
            setFrame(newFrame, display: false)
        }
    }
}

extension OnitRegularPanel: OnitPanel {
    
    func adjustSize() { }
    
    func toggleFullscreen() { }
    
    func updatePosition() { }
    
    func show() {
        setupFrame()
        
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
    }
    
    func hide() {
        orderOut(nil)
        delegate = nil
        contentView = nil
    }
}

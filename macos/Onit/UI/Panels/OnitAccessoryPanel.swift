//
//  OnitAccessoryPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 27/03/2025.
//

import Defaults
import SwiftUI

@MainActor
class OnitAccessoryPanel: NSPanel {
    
    override var canBecomeKey: Bool {
        return true
    }
    
    private let width = ContentView.idealWidth
    
    var dragDetails: PanelDraggingDetails = .init()
    var isAnimating: Bool = false
    var wasAnimated: Bool = false
    var animatedFromLeft: Bool = false
    var resizedApplication: Bool = false
    
    init(state: OnitPanelState) {
        var windowWidth = width
        
        if let savedWidth = Defaults[.panelWidth] {
            windowWidth = savedWidth
        }
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: 0),
            styleMask: [.nonactivatingPanel, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = NSColor.clear
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        delegate = state
        isFloatingPanel = true
        
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        let contentView = ContentView()
            .modelContainer(state.container)
            .environment(\.windowState, state)

        let panelContentView = NSHostingView(rootView: contentView)
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = .clear

        self.contentView = panelContentView
        self.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))

        show()
        
        Defaults[.defaultPanelFrame] = frame
    }
    
    private func calculatePanelFrame(windowWidth: CGFloat) -> NSRect? {
        if let screen = findScreen() {
            let visibleFrame = screen.visibleFrame
            let windowHeight = frame.height
            
            let finalXPosition: CGFloat
            
            switch Defaults[.panelPosition] {
            case .topLeft:
                finalXPosition = visibleFrame.origin.x
            case .topCenter:
                finalXPosition = visibleFrame.origin.x + (visibleFrame.width - windowWidth) / 2
            case .topRight:
                finalXPosition = visibleFrame.origin.x + visibleFrame.width - windowWidth
            }
            
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - windowHeight
            
            return NSRect(
                x: finalXPosition,
                y: finalYPosition,
                width: windowWidth,
                height: windowHeight
            )
        }
        return nil
    }
}

extension OnitAccessoryPanel: OnitPanel {
    
    func setLevel(_ level: NSWindow.Level) {
        self.level = level
    }
    
    func adjustSize() {
        guard let contentView = contentView else { return }
        
        // Re-measure the SwiftUI hierarchy
        contentView.layoutSubtreeIfNeeded()
        let idealSize = contentView.fittingSize

        // Clamp the window height so it doesn't fall off-screen
        guard let screen = screen ?? NSScreen.main else { return }
        
        let visibleFrame = screen.visibleFrame
        let maxAllowedHeight = visibleFrame.height - ContentView.bottomPadding
        let newHeight = min(idealSize.height, maxAllowedHeight)
        let currentWidth = frame.width

        // Keep the top edge in place
        let newX = frame.origin.x
        let newY = visibleFrame.origin.y + visibleFrame.height - newHeight

        // Apply changes
        setFrame(
            NSRect(x: newX, y: newY, width: currentWidth, height: newHeight),
            display: true
        )
    }
    
    func toggleFullscreen() {
        if let screen = findScreen() {
            let visibleFrame = screen.visibleFrame

            if Defaults[.isPanelExpanded] {
                let defaultPanelFrame = Defaults[.defaultPanelFrame]
                
                setFrame(defaultPanelFrame, display: true, animate: true)
            } else {
                Defaults[.defaultPanelFrame] = frame
                
                setFrame(visibleFrame, display: true, animate: true)
            }
            
            Defaults[.isPanelExpanded].toggle()
        }
    }
    
    func updatePosition() {
        let windowWidth = frame.width
        
        if let newFrame = calculatePanelFrame(windowWidth: windowWidth) {
            setFrame(newFrame, display: true, animate: false)
        }
    }
    
    func show() {
        var windowWidth = frame.width
        
        if let savedWidth = Defaults[.panelWidth] {
            windowWidth = savedWidth
        }
        
        if let newFrame = calculatePanelFrame(windowWidth: windowWidth) {
            setFrame(newFrame, display: true, animate: false)
        }
        
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
    }
    
    func hide() {
        if !Defaults[.isPanelExpanded] {
            Defaults[.panelWidth] = frame.width
        } else {
            Defaults[.isPanelExpanded] = false
        }
        
        orderOut(nil)
        delegate = nil
        contentView = nil
    }
}

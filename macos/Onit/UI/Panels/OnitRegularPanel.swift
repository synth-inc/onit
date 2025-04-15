//
//  OnitRegularPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 26/03/2025.
//

import ApplicationServices
import Defaults
import SwiftUI

@MainActor
class OnitRegularPanel: NSPanel {
    
    var _level: NSWindow.Level = .floating {
        didSet {
            level = _level
        }
    }
    
    override var canBecomeKey: Bool {
        return _level == .floating
    }
    
    private let state: OnitPanelState
    private let width = ContentView.idealWidth
    
    var dragDetails: PanelDraggingDetails = .init()
    var isProgrammaticMove: Bool = false
    var isAnimating: Bool = false
    var wasAnimated: Bool = false
    var animatedFromLeft: Bool = false
    var resizedApplication: Bool = false
    var onitContentView: ContentView?
    
    init(state: OnitPanelState) {
        self.state = state
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 0),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
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
        isFloatingPanel = false
        animationBehavior = .none
        collectionBehavior = [.moveToActiveSpace]
        
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        let contentView = ContentView()
            .modelContainer(state.container)
            .environment(\.windowState, state)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 14
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = .clear

        self.contentView = hostingView
        self.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: self
        )
        
        show()
    }
    
    @objc func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let activeWindow = state.trackedWindow?.element,
              wasAnimated, !isAnimating, !isProgrammaticMove else { return }
        
        let currentPosition = window.frame.origin

        if currentPosition != dragDetails.lastPosition {
            dragDetails.isDragging = true
            
            if let activeWindowPosition = activeWindow.position(),
               let activeWindowSize = activeWindow.size() {
                
                let deltaX: CGFloat
                if dragDetails.lastPosition == .zero {
                    let expectedX = activeWindowPosition.x + activeWindowSize.width - (TetheredButton.width / 2)
                    deltaX = currentPosition.x - expectedX
                } else {
                    deltaX = currentPosition.x - dragDetails.lastPosition.x
                }
                let newX = activeWindowPosition.x + deltaX
                
                var menuBarHeight: CGFloat = 40
                if let screen = screen {
                    menuBarHeight = screen.frame.height - screen.visibleFrame.height
                }
                let newY = -currentPosition.y + menuBarHeight
                
                _ = activeWindow.setPosition(NSPoint(x: newX, y: newY))
            }
            
            dragDetails.lastPosition = currentPosition
            dragDetails.dragEndTimer?.invalidate()
            dragDetails.dragEndTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                Task { @MainActor in
                    self.dragDetails = .init()
                }
            }
        }
    }
    
    private func setupFrame() {
        guard let activeWindow = state.trackedWindow?.element,
              let position = activeWindow.position(),
              let size = activeWindow.size() else {
            
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
            return
        }
        
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.frame
        let onitHeight = min(size.height, screenFrame.height - ContentView.bottomPadding)
        let onitX = position.x + size.width - (width / 2)
        let onitY = screenFrame.maxY - (position.y + onitHeight)
        let newFrame = NSRect(
            x: onitX,
            y: onitY,
            width: width,
            height: onitHeight
        )
        
        setFrame(newFrame, display: false)
    }
    
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        isProgrammaticMove = true
        super.setFrame(frameRect, display: flag)
        isProgrammaticMove = false
    }
}

extension OnitRegularPanel: OnitPanel {
    
    func setLevel(_ level: NSWindow.Level) {
        self._level = level
    }
    
    func adjustSize() { }
    
    func toggleFullscreen() { }
    
    func updatePosition() { }
    
    func show() {
        makeKeyAndOrderFront(nil)
        setupFrame()
    }
    
    func hide() {
        orderOut(nil)
        delegate = nil
        contentView = nil
    }
}

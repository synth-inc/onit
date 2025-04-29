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
    
    let state: OnitPanelState
    private var width: CGFloat
    private let minWidth: CGFloat = 300 // Minimum width constraint
    
    var dragDetails: PanelDraggingDetails = .init()
    var isAnimating: Bool = false
    var wasAnimated: Bool = false
    var animatedFromLeft: Bool = false
    var resizedApplication: Bool = false
    var isResizing: Bool = false
    var onitContentView: ContentView?
    
    init(state: OnitPanelState) {
        self.state = state
        self.width = Defaults[.panelWidth] ?? ContentView.idealWidth
        
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
        
        let resizeOverlay = NSHostingView(rootView: 
            ZStack(alignment: .bottomLeading) {
                Color.clear // Transparent background
                ResizeHandle(
                    onDrag: { [weak self] deltaX in
                        self?.isResizing = true
                        self?.resizePanel(byWidth: deltaX)
                    },
                    onDragEnded: { [weak self] in
                        guard let self = self else { return }
                        Defaults[.panelWidth] = self.width
                        self.isResizing = false
                        self.state.repositionPanel()
                    }
                )
                .padding(.leading, 8)
                .padding(.bottom, 8)
            }
            .allowsHitTesting(true) // Ensure the ZStack intercepts all events
            .contentShape(Rectangle()) // Make the entire area respond to gestures
        )
        resizeOverlay.wantsLayer = true
        resizeOverlay.layer?.backgroundColor = .clear
        
        if let contentHostingView = self.contentView {
            resizeOverlay.frame = contentHostingView.bounds
            contentHostingView.addSubview(resizeOverlay)
            resizeOverlay.autoresizingMask = [.width, .height]
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillMove),
            name: NSWindow.willMoveNotification,
            object: self
        )
        
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            if event.window === self {
                self?.dragDetails.isDragging = true
            }
            return event
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            if self?.dragDetails.isDragging == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.dragDetails = .init()
                }
            }
        }
        
        show()
    }
    
    @objc private func windowWillMove(_ notification: Notification) {
        dragDetails.isDragging = true
    }
    
    private func setupFrame() {
        guard let activeWindow = state.trackedWindow?.element,
              let windowFrame = activeWindow.getFrame(convertedToGlobalCoordinateSpace: true),
              let screenFrame = windowFrame.findScreen()?.frame else {
            
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
        
        let onitHeight = min(windowFrame.height, screenFrame.height - ContentView.bottomPadding)
        let onitX = windowFrame.origin.x + windowFrame.width - (width / 2)
        let onitY = windowFrame.origin.y
        let newFrame = NSRect(
            x: onitX,
            y: onitY,
            width: width,
            height: onitHeight
        )
        
        setFrame(newFrame, display: false)
    }
}

extension OnitRegularPanel: OnitPanel {
    
    func setLevel(_ level: NSWindow.Level) {
        self._level = level
    }
    
    func adjustSize() { }
    
    func toggleFullscreen() { }
    
    func updatePosition() { }
    
    func resizePanel(byWidth deltaWidth: CGFloat) {
        guard !isAnimating else { return }
        
        let originalMovableState = isMovableByWindowBackground
        isMovableByWindowBackground = false
        
        let newWidth = max(minWidth, width - deltaWidth)
        width = newWidth
        
        let rightEdgeX = frame.maxX
        
        let newFrame = NSRect(
            x: rightEdgeX - newWidth, // Keep right edge fixed
            y: frame.origin.y,
            width: newWidth,
            height: frame.height
        )
        
        setFrame(newFrame, display: true)
        
        if frame.maxX != rightEdgeX {
            let adjustedFrame = NSRect(
                x: rightEdgeX - newWidth,
                y: frame.origin.y,
                width: newWidth,
                height: frame.height
            )
            setFrame(adjustedFrame, display: true)
        }
        
        // Update the static property
        ContentView.idealWidth = newWidth
        
        isMovableByWindowBackground = originalMovableState
    }
    
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




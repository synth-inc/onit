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
    var width: CGFloat
    static let minWidth: CGFloat = 320 // Minimum width constraint
    static let minAppWidth = 500.0

    var dragDetails: PanelDraggingDetails = .init()
    var isAnimating: Bool = false
    var wasAnimated: Bool = false
    var animatedFromLeft: Bool = false
    var resizedApplication: Bool = false
    var isResizing: Bool = false
    var originalFrame : NSRect = .zero
    @Published var isTetheredButtonHovered = false
    
    init(state: OnitPanelState) {
        self.state = state
        self.width = state.panelWidth
        
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
        isMovable = PanelStateCoordinator.shared.isPanelMovable
        isMovableByWindowBackground = PanelStateCoordinator.shared.isPanelMovable
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
            .padding(.leading, TetheredButton.width / 2)
        
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
                        guard let self = self else { return }
                        self.isResizing = true
                        if self.originalFrame == .zero {
                            self.originalFrame = NSRect(origin: frame.origin, size: frame.size)
                            }
                        self.resizePanel(byWidth: deltaX)
                    },
                    onDragEnded: { [weak self] in
                        guard let self = self else { return }
                        Defaults[.panelWidth] = self.width
                        self.panelResizeEnded(originalPanelWidth: self.originalFrame.width)
                        self.originalFrame = .zero
                        self.isResizing = false
                    },
                    disableHover: Binding(
                        get: { self.isTetheredButtonHovered },
                        set: { self.isTetheredButtonHovered = $0 }
                    )
                )
            }
            .allowsHitTesting(true)
            .contentShape(Rectangle())
        )
        resizeOverlay.wantsLayer = true
        resizeOverlay.layer?.backgroundColor = CGColor.clear
        
        // The target for dragging is be the entire height, and 6px wide, starting at TetheredButton.width/ 2 to leave room for the TetheredButton. 
        resizeOverlay.frame = NSRect(x: (TetheredButton.width / 2) - 2, y: 0, width: 8, height: frame.height)
        hostingView.addSubview(resizeOverlay)
        resizeOverlay.autoresizingMask = [.maxXMargin, .height]

        // Create a separate hosting view for the TetheredButton
        let tetheredButtonView = NSHostingView(rootView: 
            TetheredButton(isHovered: Binding(
                get: { self.isTetheredButtonHovered },
                set: { self.isTetheredButtonHovered = $0 }
            ))
                .modelContainer(state.container)
                .environment(\.windowState, state)
        )
        tetheredButtonView.wantsLayer = true
        tetheredButtonView.frame = NSRect(x: 0, y: 0, width: TetheredButton.width, height: frame.height)
        hostingView.addSubview(tetheredButtonView)
        tetheredButtonView.autoresizingMask = [.maxXMargin, .height]

        if PanelStateCoordinator.shared.isPanelMovable {
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
    
    func resizePanel(byWidth deltaWidth: CGFloat) {
        guard !isAnimating else { return }
        
        let newWidth = width - deltaWidth
        
        if (newWidth >= OnitRegularPanel.minWidth) {
            width = newWidth
            
            // Always use the original position to calculate the new frame
            // This prevents accumulated drift during resize
            
            let newFrame = NSRect(
                x: originalFrame.maxX - newWidth,
                y: frame.origin.y,
                width: newWidth,
                height: frame.height
            )
                
            setFrame(newFrame, display: true)
            state.panelWidth = newWidth // Update state property
        }
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




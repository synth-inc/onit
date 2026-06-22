//
//  CenteredWindow.swift
//  Onit
//
//  Created by Loyd Kim on 10/20/25.
//

import SwiftUI

class CenteredWindow<SwiftUIView: View>: NSWindow {
    // MARK: - Types
    
    typealias WindowSize = (width: CGFloat, height: CGFloat)
    typealias TitleBarButtonsOffset = (xOffset: CGFloat, yOffset: CGFloat)
    
    // MARK: - Properties
    
    var hostingController: NSHostingController<SwiftUIView>
    private var windowLevel: NSWindow.Level
    private var hideTitleBar: Bool
    private var canResize: Bool
    private var canDrag: Bool
    private var canCloseWithEsc: Bool
    private var windowSize: WindowSize?
    private var titleBarButtonsOffset: TitleBarButtonsOffset?
    
    // MARK: - Initializer
    
    init(
        rootView: SwiftUIView,
        windowLevel: NSWindow.Level = NSWindow.Level.normal,
        hideTitleBar: Bool = false,
        canResize: Bool = false,
        canDrag: Bool = true,
        canCloseWithEsc: Bool = true,
        windowSize: WindowSize? = nil,
        titleBarButtonsOffset: TitleBarButtonsOffset? = nil,
        
        contentRect: NSRect = NSRect(x: 0, y: 0, width: 1, height: 1),
        styleMask: NSWindow.StyleMask = [],
        backing: NSWindow.BackingStoreType = NSWindow.BackingStoreType.buffered,
        defer flag: Bool = false
    ) {
        self.hostingController = NSHostingController(rootView: rootView)
        self.windowLevel = windowLevel
        self.hideTitleBar = hideTitleBar
        self.canResize = canResize
        self.canDrag = canDrag
        self.canCloseWithEsc = canCloseWithEsc
        self.windowSize = windowSize
        self.titleBarButtonsOffset = titleBarButtonsOffset
        
        var rect = contentRect
        if let windowSize = self.windowSize {
            rect = NSRect(
                x: 0,
                y: 0,
                width: windowSize.width,
                height: windowSize.height
            )
        }
        
        var mask = styleMask
        if !hideTitleBar {
            mask.formUnion([.titled, .closable, .miniaturizable, .fullSizeContentView])
        }
        
        super.init(
            contentRect: rect,
            styleMask: mask,
            backing: backing,
            defer: flag
        )
        
        self.setupWindow()
    }
    
    // MARK: - Private Variables
    
    private var observers: [NSObjectProtocol] = []
    
    // MARK: - Public Functions
    
    func cleanupObservers() {
        for observer in self.observers {
            NotificationCenter.default.removeObserver(observer)
        }
        self.observers.removeAll()
    }
    
    func updateRootView(_ rootView: SwiftUIView) {
        self.hostingController.rootView = rootView
    }
    
    // MARK: - Private Functions
    
    private func updateSize() {
        let hostView = self.hostingController.view
        hostView.layoutSubtreeIfNeeded()
        
        var size = hostView.fittingSize
        if size.width <= 0 || size.height <= 0 {
            size = NSSize(width: 1, height: 1)
        }
        
        self.setContentSize(size)
        self.center()
    }
    
    /// Allows the window to dynamically update its size based on the size of its SwiftUI view.
    private func observeAndFitToSwiftUIViewSize() {
        let contentSizeObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: self.hostingController.view,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.updateSize()
            }
        }
        self.observers.append(contentSizeObserver)
    }
    
    private func adjustTitlebarButtonsPosition(
        _ xOffset: CGFloat,
        _ yOffset: CGFloat
    ) {
        guard let closeButton = self.standardWindowButton(.closeButton),
              let miniaturizeButton = self.standardWindowButton(.miniaturizeButton),
              let buttonContainer = closeButton.superview
        else {
            return
        }
        
        buttonContainer.layoutSubtreeIfNeeded()
        
        for button in [closeButton, miniaturizeButton] {
            var origin = button.frame.origin
            origin.x += xOffset
            origin.y -= yOffset
            button.setFrameOrigin(origin)
        }
    }
    
    private func setupWindow() {
        self.backgroundColor = NSColor.clear
        self.hasShadow = true
        self.isOpaque = false
        self.isRestorable = false
        self.center()
        self.level = self.windowLevel
        self.isMovableByWindowBackground = self.canDrag
        self.contentView = self.hostingController.view
        
        if self.hideTitleBar {
            self.styleMask.remove(.titled)
        } else {
            self.titleVisibility = .hidden
            self.titlebarAppearsTransparent = true
            self.standardWindowButton(.zoomButton)?.isHidden = true
        }
        
        if self.canResize {
            self.styleMask.insert(.resizable)
        } else {
            self.styleMask.remove(.resizable)
        }
        
        if self.windowSize == nil {
            self.hostingController.view.postsFrameChangedNotifications = true
            /// Prevents ambiguous resizing; makes window properly fit the size of its hosting controller view (i.e. the SwiftUI view).
            self.hostingController.view.setContentHuggingPriority(.required, for: .horizontal)
            self.hostingController.view.setContentHuggingPriority(.required, for: .vertical)
            self.updateSize()

            self.observeAndFitToSwiftUIViewSize()
        } else {
            self.cleanupObservers()
        }
        
        if let (xOffset, yOffset) = self.titleBarButtonsOffset {
            self.adjustTitlebarButtonsPosition(xOffset, yOffset)
        }
    }
    
    // MARK: - Overrides
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if self.canCloseWithEsc {
            if event.keyCode == 53 {
                self.close()
                return
            }
            super.keyDown(with: event)
        }
    }
}

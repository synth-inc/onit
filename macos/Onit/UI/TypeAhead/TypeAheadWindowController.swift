//
//  TypeAheadWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 14/02/2025.
//


import AppKit
import SwiftUI

@MainActor
class TypeAheadWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Singleton instance
    
    static let shared = TypeAheadWindowController()

    // MARK: - Properties

    private let state: TypeAheadState
    private var window: TypeAheadWindow?
    private var positionObserver: Task<Void, Never>?
    private var menuWindow: TypeAheadWindow?
    
    var lastActiveApp: NSRunningApplication?
    
    private let screenPadding: CGFloat = 16

    // MARK: - Initializers

    override init() {
        self.state = TypeAheadState.shared

        super.init()

        let contentView = TypeAheadView().fixedSize()
        let hostingController = NSHostingController(rootView: contentView)
        let window = TypeAheadWindow(contentViewController: hostingController)
        
        let menuView = TypeAheadMenuView().fixedSize()
        let menuHostingController = NSHostingController(rootView: menuView)
        
        let menuWindow = TypeAheadWindow(contentViewController: menuHostingController)
        
        menuWindow.configure(self)
        window.configure(self)
        
        self.window = window
        self.menuWindow = menuWindow 
        
        setupEventMonitor()
        setupPositionObserver()
    }

    private func setupEventMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            guard modifiers.isEmpty, event.keyCode == 48 else { return }
            
            Task { @MainActor in
                self.state.insertSuggestion()
            }
        }
    }

    private func setupPositionObserver() {
        positionObserver?.cancel()
        
        positionObserver = Task { [weak self] in
            let manager = AccessibilityNotificationsManager.shared
            
            for await position in manager.$inputPosition.values {
                if self?.updateWindowPosition(at: position) == false {
                    self?.positionWindowAtMouse()
                }
            }
        }
    }

    // MARK: - Functions

    func showWindow() {
        updateWindowSize()
        if updateWindowPosition(at: AccessibilityNotificationsManager.shared.inputPosition) == false {
            positionWindowAtMouse()
        }
        bringToFront()
    }

    func bringToFront() {
        window?.alphaValue = 1.0
        window?.orderFront(nil)
    }

    func closeWindow() {
        guard let window = window else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 0.0
            })
    }

    func showMenu() {
        guard let window = window,
              let menuWindow = menuWindow else { return }
        
        let windowFrame = window.frame
        var menuPoint = NSPoint(
            x: windowFrame.maxX - 16,
            y: windowFrame.maxY - 4
        )
        
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(menuPoint) }) else {
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let menuSize = menuWindow.frame.size
        
        if menuPoint.x + menuSize.width > visibleFrame.maxX - screenPadding {
            menuPoint.x = visibleFrame.maxX - menuSize.width - screenPadding
        }
        
        if menuPoint.x < visibleFrame.minX + screenPadding {
            menuPoint.x = visibleFrame.minX + screenPadding
        }
        
        if menuPoint.y > visibleFrame.maxY - screenPadding {
            menuPoint.y = visibleFrame.maxY - screenPadding
        }
        
        if menuPoint.y - menuSize.height < visibleFrame.minY + screenPadding {
            menuPoint.y = visibleFrame.minY + menuSize.height + screenPadding
        }
        
        menuWindow.setFrameTopLeftPoint(menuPoint)
        menuWindow.orderFront(nil)
    }
    
    func hideMenu() {
        menuWindow?.close()
    }

    // MARK: - Private Functions
    
    private func updateWindowSize() {
        guard let window = window else { return }
        guard let contentView = window.contentViewController?.view else { return }

        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        window.setContentSize(contentSize)
    }

    private func updateWindowPosition(at position: CGPoint?) -> Bool {
        if let window = window, var position = position {
            
            position.y -= window.frame.height
            
            for screen in NSScreen.screens {
                if screen.frame.contains(position) {
                    let screenHeight = screen.frame.height
                    let adjustedY = screenHeight - position.y
                    
                    window.setFrameOrigin(NSPoint(x: position.x, y: adjustedY))
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    private func positionWindowAtMouse() {
        guard let window = window else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(mouseLocation, $0.frame, false)
        }) else { return }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        let localMouseLocation = NSPoint(
            x: mouseLocation.x - screenFrame.origin.x,
            y: mouseLocation.y - screenFrame.origin.y
        )
        
        let adjustedMouseY = localMouseLocation.y - 15
        
        let windowFrame = window.frame
        var originX = localMouseLocation.x - windowFrame.width / 2
        var originY = adjustedMouseY - windowFrame.height
        
        originX = max(
            visibleFrame.minX - screenFrame.origin.x,
            min(originX, visibleFrame.maxX - screenFrame.origin.x - windowFrame.width)
        )
        
        if originY < visibleFrame.minY - screenFrame.origin.y {
            originY = adjustedMouseY + 10
        }
        
        let globalOrigin = NSPoint(
            x: originX + screenFrame.origin.x,
            y: originY + screenFrame.origin.y
        )
        
        window.setFrameOrigin(globalOrigin)
    }

    deinit {
        positionObserver?.cancel()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        
    }
}

class TypeAheadWindow: NSWindow {
    private var lastActiveApp: NSRunningApplication?
    
    func configure(_ delegate: TypeAheadWindowController) {
        styleMask = [.borderless]
        isOpaque = false
        backgroundColor = .clear
        level = .popUpMenu
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = false
        self.delegate = delegate
        
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.masksToBounds = true
            
            let eventView = MouseTrackingView(frame: contentView.bounds)
            eventView.autoresizingMask = [.width, .height]
            eventView.delegate = delegate
            contentView.addSubview(eventView)
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func becomeKey() {
        
    }
    
    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            lastActiveApp = NSWorkspace.shared.frontmostApplication
            super.sendEvent(event)
            if let app = lastActiveApp {
                DispatchQueue.main.async {
                    app.activate(options: .activateAllWindows)
                }
            }
        default:
            super.sendEvent(event)
        }
    }
}

class MouseTrackingView: NSView {
    weak var delegate: TypeAheadWindowController?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let lastActiveApp = NSWorkspace.shared.frontmostApplication {
            delegate?.lastActiveApp = lastActiveApp
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if let lastActiveApp = delegate?.lastActiveApp {
            lastActiveApp.activate(options: .activateAllWindows)
        }
    }
}

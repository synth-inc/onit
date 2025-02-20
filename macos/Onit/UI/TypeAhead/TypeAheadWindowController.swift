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
    private let contentView: TypeAheadView?
    private var window: NSWindow?
    private var positionObserver: Task<Void, Never>?

    // MARK: - Initializers

    override init() {
        self.state = TypeAheadState.shared
        self.contentView = TypeAheadView()

        super.init()

        let contentView = contentView.fixedSize()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false

        self.window = window
        
        setupEventMonitor()
        setupPositionObserver()
    }

    private func setupEventMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            if event.keyCode == 48 {
                Task { @MainActor in
                    if !self.state.completion.isEmpty {
                        self.state.insertSuggestion()
                    }
                }
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
        window?.makeKeyAndOrderFront(nil)
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

    // MARK: - Private Functions
    
    private func updateWindowSize() {
        guard let window = window else { return }
        guard let contentView = window.contentViewController?.view else { return }

        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        window.setContentSize(contentSize)
    }

    private func updateWindowPosition(at position: CGPoint?) -> Bool {
        guard let window = window,
              let position = position,
              let screenHeight = NSScreen.main?.frame.height else {
            
            return false
        }
        
        let adjustedY = screenHeight - position.y
        
        window.setFrameOrigin(NSPoint(x: position.x, y: adjustedY))
        
        return true
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

//
//  AutoCompleteWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 14/02/2025.
//


import AppKit
import SwiftUI

@MainActor
class AutoCompleteWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Singleton instance
    
    static let shared = AutoCompleteWindowController()

    // MARK: - Properties

    private let state: AutoCompleteState
    private let contentView: AutoCompleteView?
    private var window: NSWindow?

    // MARK: - Initializers

    override init() {
        self.state = AutoCompleteState.shared
        self.contentView = AutoCompleteView()

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

    // MARK: - Functions

    func showWindow() {
        updateWindowSize()
        positionWindow()
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
            },
            completionHandler: {
                window.orderOut(nil)
            })
    }

    // MARK: - Private Functions
    
    private func positionWindow(at position: CGPoint) {
        guard let window = window else { return }
        
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let adjustedY = screenHeight - position.y
        
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: position.x, y: adjustedY)) }) {
            let visibleFrame = screen.visibleFrame
            
            let windowFrame = window.frame
            var originX = position.x - windowFrame.width / 2
            var originY = adjustedY - windowFrame.height
            
            originX = max(visibleFrame.minX, min(originX, visibleFrame.maxX - windowFrame.width))
            originY = max(visibleFrame.minY, min(originY, visibleFrame.maxY - windowFrame.height))
            
            window.setFrameOrigin(NSPoint(x: originX, y: originY))
        }
    }

    private func positionWindow() {
        guard let window = window else {
            print("No overlay window found.")
            return
        }

        let mouseLocation = NSEvent.mouseLocation

        guard
            let screen = NSScreen.screens.first(where: {
                NSMouseInRect(mouseLocation, $0.frame, false)
            })
        else {
            print("No screen contains the mouse location.")
            return
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Convert mouse location to local screen coordinates
        let localMouseLocation = NSPoint(
            x: mouseLocation.x - screenFrame.origin.x,
            y: mouseLocation.y - screenFrame.origin.y
        )

        // Adjust mouse Y-coordinate to position the window lower
        let adjustedMouseY = localMouseLocation.y - 15  // Adjust this value as needed

        let overlayWidth = window.frame.width
        let overlayHeight = window.frame.height

        // Calculate the overlay's origin point
        var overlayOriginX = localMouseLocation.x - overlayWidth / 2
        var overlayOriginY = adjustedMouseY - overlayHeight

        // Ensure the overlay doesn't go off-screen horizontally
        overlayOriginX = max(
            visibleFrame.minX - screenFrame.origin.x,
            min(overlayOriginX, visibleFrame.maxX - screenFrame.origin.x - overlayWidth)
        )

        // If the overlay would go off the bottom of the screen, position it above the cursor
        if overlayOriginY < visibleFrame.minY - screenFrame.origin.y {
            overlayOriginY = adjustedMouseY + overlayHeight + 10  // Position above the cursor
        }

        // Convert overlay origin back to global screen coordinates
        let globalOverlayOrigin = NSPoint(
            x: overlayOriginX + screenFrame.origin.x,
            y: overlayOriginY + screenFrame.origin.y
        )

        window.setFrameOrigin(globalOverlayOrigin)
    }

    private func updateWindowSize() {
        guard let window = window else { return }
        guard let contentView = window.contentViewController?.view else { return }

        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        window.setContentSize(contentSize)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        
    }
}

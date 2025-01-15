//
//  ModelSelectionWindowController.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI
import AppKit

@MainActor
class ModelSelectionWindowController: NSObject, NSWindowDelegate {
    var overlayWindow: NSWindow?
    weak var model: OnitModel?

    init(model: OnitModel) {
        self.model = model
        super.init()
        createOverlayWindow()
    }

    func createOverlayWindow() {
        let contentView = ModelSelectionView()
            .environment(\.model, model!)
            .frame(width: 300, height: 400)

        let hostingController = NSHostingController(rootView: contentView)

        let window = ModelSelectionWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.delegate = self

        overlayWindow = window

        overlayWindow?.alphaValue = 1.0
        positionWindow()
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    func positionWindow() {
        guard let overlayWindow = overlayWindow else {
            print("No overlay window found.")
            return
        }

        let mouseLocation = NSEvent.mouseLocation

        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
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

        let overlayWidth = overlayWindow.frame.width
        let overlayHeight = overlayWindow.frame.height

        // Calculate the overlay's origin point
        var overlayOriginX = localMouseLocation.x - overlayWidth / 2
        var overlayOriginY = localMouseLocation.y - overlayHeight - 10 // Offset below the cursor

        // Ensure the overlay doesn't go off-screen horizontally
        overlayOriginX = max(
            visibleFrame.minX - screenFrame.origin.x,
            min(overlayOriginX, visibleFrame.maxX - screenFrame.origin.x - overlayWidth)
        )

        // If the overlay goes off the bottom of the screen, position it above the cursor
        if overlayOriginY < visibleFrame.minY - screenFrame.origin.y {
            overlayOriginY = localMouseLocation.y + 10 // Offset above the cursor
        }

        // Convert overlay origin back to global screen coordinates
        let globalOverlayOrigin = NSPoint(
            x: overlayOriginX + screenFrame.origin.x,
            y: overlayOriginY + screenFrame.origin.y
        )

        overlayWindow.setFrameOrigin(globalOverlayOrigin)
    }

    func windowDidResignKey(_ notification: Notification) {
        closeOverlay()
    }

    func closeOverlay() {
        guard let overlayWindow = overlayWindow else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            overlayWindow.animator().alphaValue = 0.0
        }, completionHandler: {
            overlayWindow.orderOut(nil)
            overlayWindow.alphaValue = 1.0
            self.overlayWindow = nil
            self.model?.modelSelectionWindowController = nil
        })
    }
}

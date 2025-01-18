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
    var eventMonitor: Any?
    var localEventMonitor: Any?

    init(model: OnitModel) {
        self.model = model
        super.init()
        createOverlayWindow()
        startEventMonitoring()
    }

    func createOverlayWindow() {
        let contentView = ModelSelectionView()
            .environment(\.model, model!)
            .fixedSize()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .modalPanel
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false

        overlayWindow = window
        updateOverlayWindowSize()
        positionWindow()
        overlayWindow?.alphaValue = 1.0
        overlayWindow?.orderFront(nil)
    }

    func startEventMonitoring() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseDownOutside(event)
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseDownOutside(event)
            return event
        }
    }

    func handleMouseDownOutside(_ event: NSEvent) {
        guard let overlayWindow = overlayWindow else { return }

        let clickLocation = NSEvent.mouseLocation

        if !overlayWindow.frame.contains(clickLocation) {
            closeOverlay()
        }
    }

    func stopEventMonitoring() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }

        if let localEventMonitor = localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
    }

    func windowWillClose(_ notification: Notification) {
        stopEventMonitoring()
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

        // Adjust mouse Y-coordinate to position the window lower
        let adjustedMouseY = localMouseLocation.y - 15 // Adjust this value as needed

        let overlayWidth = overlayWindow.frame.width
        let overlayHeight = overlayWindow.frame.height

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
            overlayOriginY = adjustedMouseY + overlayHeight + 10 // Position above the cursor
        }

        // Convert overlay origin back to global screen coordinates
        let globalOverlayOrigin = NSPoint(
            x: overlayOriginX + screenFrame.origin.x,
            y: overlayOriginY + screenFrame.origin.y
        )

        overlayWindow.setFrameOrigin(globalOverlayOrigin)
    }

    func updateOverlayWindowSize() {
        guard let overlayWindow = overlayWindow else { return }
        guard let contentView = overlayWindow.contentViewController?.view else { return }
        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        overlayWindow.setContentSize(contentSize)
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
            self.stopEventMonitoring()
        })
    }
}

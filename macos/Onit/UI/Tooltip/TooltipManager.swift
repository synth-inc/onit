//
//  TooltipManager.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import SwiftUI

@MainActor
class TooltipManager {
    
    // MARK: - Singleton
    
    static let shared = TooltipManager()
    static let animationDuration: TimeInterval = 0.1

    // MARK: - Properties
    
    var tooltipWindow: NSWindow?
    var tooltipTask: Task<Void, Never>?
    var isTooltipActive = false
    var animateOut = true
    
    
    // MARK: - Functions
    
    func setTooltip(
        _ tooltip: Tooltip?,
        tooltipConfig: TooltipConfig? = nil,
        delayStart: Double = 0.4,
        delayEnd: Double = 0.0,
        animateOut: Bool = true
    ) {
        tooltipTask?.cancel()
        self.animateOut = animateOut
        if let tooltip {
            if isTooltipActive {
                resetTooltip(tooltip, tooltipConfig)
                updateTooltipWindowSize()
                moveTooltip()
                showWindowWithoutAnimation()
            } else {
                tooltipTask = Task {
                    try? await Task.sleep(for: .seconds(delayStart))
                    if Task.isCancelled { return }
                    isTooltipActive = true
                    setupTooltip(tooltip, tooltipConfig)
                    updateTooltipWindowSize()
                    moveTooltip()
                    showWindowWithoutAnimation()
                }
            }
        } else {
            tooltipTask = Task {
                try? await Task.sleep(for: .seconds(delayEnd))
                if Task.isCancelled { return }
                isTooltipActive = false
                if self.animateOut {
                    hideWindowWithoutAnimation()
                } else {
                    hideWindowWithAnimation()
                }
            }
        }
    }

    func moveTooltip() {
        guard let tooltipWindow = self.tooltipWindow else {
            print("No tooltip window found.")
            return
        }

        let mouseLocation = NSEvent.mouseLocation

        guard let screen = NSScreen.mouse else {
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

        // Adjust mouse Y-coordinate to account for the menu bar
        let adjustedMouseY = localMouseLocation.y + 5

        let tooltipWidth = tooltipWindow.frame.width
        let tooltipHeight = tooltipWindow.frame.height

        // Calculate the tooltip's origin point
        var tooltipOriginX = localMouseLocation.x - tooltipWidth / 2
        var tooltipOriginY = adjustedMouseY - tooltipHeight

        // Ensure the tooltip doesn't go off-screen horizontally
        tooltipOriginX = max(
            visibleFrame.minX - screenFrame.origin.x,
            min(tooltipOriginX, visibleFrame.maxX - screenFrame.origin.x - tooltipWidth))

        // If the tooltip would go off the bottom of the screen, position it below the mouse pointer
        if tooltipOriginY < visibleFrame.minY - screenFrame.origin.y {
            tooltipOriginY = adjustedMouseY
        }

        // Convert tooltip origin back to global screen coordinates
        let globalTooltipOrigin = NSPoint(
            x: tooltipOriginX + screenFrame.origin.x,
            y: tooltipOriginY + screenFrame.origin.y
        )

        tooltipWindow.setFrameOrigin(globalTooltipOrigin)
    }

    func showWindowWithoutAnimation() {
        guard let tooltipWindow = self.tooltipWindow else { return }
        tooltipWindow.alphaValue = 1.0
        tooltipWindow.orderFront(nil)
    }

    func hideWindowWithAnimation() {
        guard let tooltipWindow = self.tooltipWindow else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = TooltipManager.animationDuration 
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                tooltipWindow.animator().alphaValue = 0.0
            },
            completionHandler: {
                tooltipWindow.orderOut(nil)
                tooltipWindow.alphaValue = 1.0
            })
    }

    func hideWindowWithoutAnimation() {
        guard let tooltipWindow = self.tooltipWindow else { return }
        tooltipWindow.orderOut(nil)
        tooltipWindow.alphaValue = 1.0
    }

    func setupTooltip(_ tooltip: Tooltip, _ tooltipConfig: TooltipConfig?) {
        if tooltipWindow == nil {
            let contentView = TooltipView(tooltip: tooltip, config: tooltipConfig)
            
            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(contentViewController: hostingController)
            window.styleMask = [.borderless]
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.level = .floating
            window.hasShadow = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.ignoresMouseEvents = true

            self.tooltipWindow = window
            tooltipWindow?.orderOut(nil)  // Ensures tooltip is initially hidden

            updateTooltipWindowSize()
        } else {
            resetTooltip(tooltip, tooltipConfig)
        }
    }

    func resetTooltip(_ tooltip: Tooltip, _ tooltipConfig: TooltipConfig?) {
        guard let tooltipWindow = self.tooltipWindow else {
            print("No window available to reset.")
            return
        }

        let content = TooltipView(tooltip: tooltip, config: tooltipConfig)
        
        let newHostingController = NSHostingController(rootView: content)

        tooltipWindow.contentViewController = newHostingController
        tooltipWindow.orderOut(nil)

        updateTooltipWindowSize()
    }

    func updateTooltipWindowSize() {
        guard let tooltipWindow = self.tooltipWindow else { return }
        guard let contentView = tooltipWindow.contentViewController?.view else { return }
        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        tooltipWindow.setContentSize(contentSize)
    }
}

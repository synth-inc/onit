//
//  PanelStatePinnedManager+Display.swift
//  Onit
//
//  Created by Kévin Naudin on 16/05/2025.
//

import AppKit
import Foundation

extension PanelStatePinnedManager {
    func showPanel(for state: OnitPanelState) {
        guard let screen = attachedScreen,
              let panel = state.panel,
              !panel.isAnimating,
              !panel.dragDetails.isDragging else {
            return
        }
        
        let fromFrame = NSRect(
            x: screen.visibleFrame.maxX - 2,
            y: screen.visibleFrame.minY,
            width: 0,
            height: screen.visibleFrame.height
        )
        let newFrame = NSRect(
            x: screen.visibleFrame.maxX - state.panelWidth,
            y: screen.visibleFrame.minY,
            width: state.panelWidth,
            height: screen.visibleFrame.height
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
            resizeWindows(for: screen)
        } else {
            panel.resizedApplication = false
            animateEnter(state: state,
                         panel: panel,
                         fromPanel: fromFrame,
                         toPanel: newFrame)
        }
    }
    
    func hidePanel(for state: OnitPanelState) {
        guard let panel = state.panel, !panel.isAnimating else { return }

        let toPanelX = panel.frame.maxX - 2
        let toPanel = NSRect(origin: NSPoint(x: toPanelX, y: panel.frame.minY), size: NSSize(width: 1, height: panel.frame.height))
        
        animateExit(
            state: state,
            panel: panel,
            toPanel: toPanel
        )
    }
    
    private func animateEnter(
        state: OnitPanelState,
        panel: OnitPanel,
        fromPanel: CGRect,
        toPanel: CGRect
    ) {
        guard !panel.isAnimating else { return }
        
        panel.isAnimating = true
        panel.setFrame(fromPanel, display: false)
        panel.alphaValue = 1

        // Hide the existing UI before animating the panel in.
        state.animateChatView = true
        state.showChatView = false
        
        // Enable layer backing for smoother animation
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.shouldRasterize = true
        panel.contentView?.layer?.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(toPanel, display: false)
        } completionHandler: {
            // Disable rasterization after animation
            panel.contentView?.layer?.shouldRasterize = false

            state.animateChatView = true
            state.showChatView = true
            panel.isAnimating = false
            panel.wasAnimated = true
            
            if let screen = self.attachedScreen ?? NSScreen.mouse {
                DispatchQueue.main.async {
                    self.resizeWindows(for: screen)
                }
            }
        }
    }
    
    private func animateExit(
        state: OnitPanelState,
        panel: OnitPanel,
        toPanel: CGRect
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        state.animateChatView = true
        state.showChatView = false
        
        // Enable layer backing for smoother animation
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.shouldRasterize = true
        panel.contentView?.layer?.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0

        resetFramesOnAppChange()
        
        
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(toPanel, display: false)
        } completionHandler: {
            // Disable rasterization after animation
            panel.contentView?.layer?.shouldRasterize = false
            panel.hide()
            panel.isAnimating = false
            panel.alphaValue = 0
            state.panel = nil

            // Once the panel is hidden, we should show the hint
            if let screen = self.attachedScreen {
                self.attachedScreen = nil
                self.showTetherWindow(activeScreen: screen)
            }
        }
    }
}

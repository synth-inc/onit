//
//  OnitPanelState+Position.swift
//  Onit
//
//  Created by Kévin Naudin on 08/04/2025.
//

import AppKit
import Foundation
import SwiftUI

extension OnitPanelState {
    
    // MARK: - Panel repositioning
    
    func repositionPanel() {
        guard let window = trackedWindow?.element,
              let windowFrame = window.frame(),
              let panel = self.panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        // Special case for Finder (desktop only)
        if TetherAppsManager.isFinderShowingDesktopOnly(activeWindow: window) {
            if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                let screenFrame = mouseScreen.frame
                let onitWidth = TetherAppsManager.minOnitWidth
                let onitHeight = screenFrame.height - ContentView.bottomPadding
                let onitY = screenFrame.maxY - onitHeight
                let onitX = screenFrame.maxX - onitWidth
                
                panel.setFrame(NSRect(
                    x: onitX,
                    y: onitY,
                    width: onitWidth,
                    height: onitHeight
                ), display: true, animate: true)
            }
            return
        }
        
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Find the primary screen (the one with origin at 0,0)
        let screens = NSScreen.screens
        let primaryScreen = screens.first { screen in
            screen.frame.origin.x == 0 && screen.frame.origin.y == 0
        } ?? NSScreen.main ?? screens.first!
        let primaryScreenFrame = primaryScreen.frame
        
        // This is the height of the dock and/or toolbar.
        let activeScreenInset = screenFrame.height - visibleFrame.height
        let fullTop = primaryScreenFrame.height - screenFrame.height - visibleFrame.minY + activeScreenInset
        let windowDistanceFromTop = windowFrame.minY - fullTop
        
        let onitWidth = TetherAppsManager.minOnitWidth
        let onitHeight = min(size.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = visibleFrame.minY + (visibleFrame.height - windowFrame.height) - windowDistanceFromTop
        
        // If the panel.wasAnimated is true, we only want to check this against the maximum X of a
        let spaceOnRight = screenFrame.maxX - (position.x + size.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + TetherAppsManager.spaceBetweenWindows
        
        if hasEnoughSpace || panel.wasAnimated {
            movePanel(onitWidth: onitWidth, onitHeight: onitHeight, onitY: onitY)
        } else {
            let screenFrame = screen.frame
            let onitWidth = TetherAppsManager.minOnitWidth
            let minAppWidth = screenFrame.width / 3
            
            let maxAvailableWidth = screenFrame.maxX - position.x - onitWidth - TetherAppsManager.spaceBetweenWindows
            
            if maxAvailableWidth >= minAppWidth {
                resizeWindowAndMovePanel(onitWidth: onitWidth, onitHeight: onitHeight, onitY: onitY, maxAvailableWidth: maxAvailableWidth)
            } else {
                moveWindowAndPanel(screenFrame: screenFrame, onitWidth: onitWidth, onitHeight: onitHeight, onitY: onitY)
            }
        }
    }
    
    func restoreWindowPosition() {
        var fromActive : NSRect? = nil
        var toActive: NSRect? = nil
        if let panel = self.panel {
            
            if let window = trackedWindow?.element,
                let initialFrame = TetherAppsManager.shared.targetInitialFrames[window],
                let curFrame = window.frame() {

                // We only try to restore the window if it was resized
                if panel.resizedApplication {
                    print("Frames found, trying to set them back ")
                    fromActive = curFrame
                    
                    var newWidth = initialFrame.width

                    // We want to make sure that we don't expand the window beyond the screen width
                    if let screenFrame = NSScreen.main?.frame {
                        newWidth = min(screenFrame.maxX - curFrame.origin.x, newWidth)
                    }
                        
                    // We also shouldn't grow it more than the panel width, in case they dragged it left.
                    newWidth = min(newWidth, curFrame.width + panel.frame.width)
                    
                    toActive = NSRect(
                        x: curFrame.origin.x,
                        y: curFrame.origin.y,
                        width: newWidth,
                        height: curFrame.height
                    )
                    TetherAppsManager.shared.targetInitialFrames.removeValue(forKey: window)
                }
            }
        

            let toPanel: NSRect
            if panel.animatedFromLeft {
                toPanel = NSRect(origin: panel.frame.origin, size: NSSize(width: 1, height: panel.frame.height))
            } else {
                let toPanelX = panel.frame.maxX - 2
                toPanel = NSRect(origin: NSPoint(x: toPanelX, y: panel.frame.minY), size: NSSize(width: 1, height: panel.frame.height))
            }
            
            animateExit(
                activeWindow: trackedWindow?.element,
                fromActive: fromActive,
                toActive: toActive,
                panel: panel,
                toPanel: toPanel
            )
        }
    }
    
    // MARK: - Layout
    
    private func movePanel(onitWidth: CGFloat, onitHeight: CGFloat, onitY: CGFloat) {
        print("movePanel")
        guard let window = trackedWindow?.element,
              let panel = panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        let fromFrame = NSRect(
            x: position.x + size.width + TetherAppsManager.spaceBetweenWindows,
            y: onitY,
            width: 0,
            height: onitHeight
        )
        let newFrame = NSRect(
            x: position.x + size.width + TetherAppsManager.spaceBetweenWindows,
            y: onitY,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
        } else {
            panel.resizedApplication = false
            animateEnter(activeWindow: nil,
                        fromActive: nil,
                        toActive: nil,
                        panel: panel,
                        fromPanel: fromFrame,
                        toPanel: newFrame
            )
        }
    }
    
    private func moveWindowAndPanel(screenFrame: CGRect, onitWidth: CGFloat, onitHeight: CGFloat, onitY: CGFloat) {
        print("moveWindowAndPanel")
        guard let window = trackedWindow?.element,
              let panel = panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        let newAppX = screenFrame.maxX - size.width - onitWidth - TetherAppsManager.spaceBetweenWindows
        let activeWindowTargetRect = CGRect(
            x: newAppX,
            y: position.y,
            width: size.width,
            height: size.height
        )
        
        let newFrame = NSRect(
            x: newAppX + size.width + TetherAppsManager.spaceBetweenWindows,
            y: onitY,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
            _ = window.setFrame(activeWindowTargetRect)
        } else {
            panel.resizedApplication = true
            let activeWindowSourceRect = CGRect(
                x: position.x,
                y: position.y,
                width: size.width,
                height: size.height
            )
            let fromFrame = NSRect(
                x: position.x + size.width, 
                y: onitY,
                width: 0,
                height: onitHeight
            )
            
            animateEnter(
                activeWindow: window,
                fromActive: activeWindowSourceRect,
                toActive: activeWindowTargetRect,
                panel: panel,
                fromPanel: fromFrame,
                toPanel: newFrame
            )
        }
    }
    
    private func resizeWindowAndMovePanel(onitWidth: CGFloat, onitHeight: CGFloat, onitY: CGFloat, maxAvailableWidth: CGFloat) {
        print("resizeWindowAndMovePanel")
        guard let window = trackedWindow?.element,
              let panel = panel,
              let windowFrame = window.frame(),
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        let activeWindowTargetRect = CGRect(
            x: position.x,
            y: position.y,
            width: maxAvailableWidth,
            height: size.height
        )
        
        let newFrame = NSRect(
            x: position.x + maxAvailableWidth + TetherAppsManager.spaceBetweenWindows,
            y: onitY,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
            _ = window.setFrame(activeWindowTargetRect)
        } else {
            panel.resizedApplication = true
            let activeWindowSourceRect = CGRect(
                x: position.x,
                y: position.y,
                width: size.width,
                height: size.height
            )
            let fromFrame = NSRect(
                x: windowFrame.maxX - 1, // 1px padding prevents animation lag when window is on edge of external monitors.
                y: onitY,
                width: 0,
                height: onitHeight
            )
            
            animateEnter(
                activeWindow: window,
                fromActive: activeWindowSourceRect,
                toActive: activeWindowTargetRect,
                panel: panel,
                fromPanel: fromFrame,
                toPanel: newFrame
            )
        }
    }
    
    // MARK: - Animations
    
    private func animateEnter(
        activeWindow: AXUIElement?,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        fromPanel: CGRect,
        toPanel: CGRect
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        panel.setFrame(fromPanel, display: false)
        panel.alphaValue = 0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(toPanel, display: false)
            panel.animator().alphaValue = 1
        } completionHandler: {
            panel.isAnimating = false
            panel.wasAnimated = true
            panel.animatedFromLeft = abs(fromPanel.maxX - toPanel.minX) <= abs(fromPanel.maxX - toPanel.maxX)
            
            if let activeWindow = activeWindow, let toActive = toActive {
                _ = activeWindow.setFrame(toActive)
            }
        }
    }
    
    private func animateExit(
        activeWindow: AXUIElement?,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        toPanel: CGRect,
        steps: Int = 10,
        duration: TimeInterval = 0.2
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        panel.alphaValue = 1
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            panel.animator().setFrame(toPanel, display: false)
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.hide()
            panel.isAnimating = false
            self.panel = nil
            
            if let activeWindow = activeWindow, let toActive = toActive {
                _ = activeWindow.setFrame(toActive)
            }
        }
    }
} 

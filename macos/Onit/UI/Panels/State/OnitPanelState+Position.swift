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
              let panel = self.panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        // Special case for Finder (desktop only)
        if isFinderShowingDesktopOnly(activeWindow: window) {
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
        let onitWidth = TetherAppsManager.minOnitWidth
        let onitHeight = min(size.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = screenFrame.maxY - (position.y + onitHeight)
        
        let spaceOnRight = screenFrame.maxX - (position.x + size.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + TetherAppsManager.spaceBetweenWindows
        
        if hasEnoughSpace {
            let newFrame = NSRect(
                x: position.x + size.width + TetherAppsManager.spaceBetweenWindows,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            )
            
            if panel.isVisible {
                panel.setFrame(newFrame, display: true, animate: true)
            } else {
                animateEnter(activeWindow: window,
                            fromActive: nil,
                            toActive: nil,
                            panel: panel,
                            fromPanel: newFrame,
                            toPanel: newFrame
                )
            }
        } else {
            let maxActiveAppWidth = screenFrame.width - onitWidth - TetherAppsManager.spaceBetweenWindows
            let activeAppWidth = min(size.width, maxActiveAppWidth)
            
            let activeWindowTargetRect = CGRect(
                x: position.x,
                y: position.y,
                width: activeAppWidth,
                height: size.height
            )
            let newFrame = NSRect(
                x: position.x + activeAppWidth + TetherAppsManager.spaceBetweenWindows,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            )

            if panel.isVisible {
                panel.setFrame(newFrame, display: true, animate: true)
                _ = window.setFrame(activeWindowTargetRect)
            } else {
                let activeWindowSourceRect = CGRect(
                    x: position.x,
                    y: position.y,
                    width: size.width,
                    height: size.height
                )
                let panelSourceRect: CGRect = panel.frame
                
                animateEnter(
                    activeWindow: window,
                    fromActive: activeWindowSourceRect,
                    toActive: activeWindowTargetRect,
                    panel: panel,
                    fromPanel: panelSourceRect,
                    toPanel: newFrame
                )
            }
        }
    }
    
    func restoreWindowPosition() {
        if let window = trackedWindow?.element,
           let initialFrame = TetherAppsManager.shared.targetInitialFrames[window] {
            
            _ = window.setFrame(initialFrame)
            TetherAppsManager.shared.targetInitialFrames.removeValue(forKey: window)
        }
        
        if let panel = self.panel {
            let toPanelX = panel.frame.minX + (panel.frame.width / 2)
            let toPanel = NSRect(origin: NSPoint(x: toPanelX, y: panel.frame.minY), size: panel.frame.size)
            
            animateExit(
                panel: panel,
                toPanel: toPanel
            )
        }
    }
    
    // MARK: - Animation methods
    
    private func animateEnter(
        activeWindow: AXUIElement,
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
            
            if let toActive = toActive {
                _ = activeWindow.setFrame(toActive)
            }
        }
    }
    
    private func animateExit(
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
        }
    }
    
    // MARK: - Helper methods
    
    private func isFinderShowingDesktopOnly(activeWindow: AXUIElement?) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        
        guard let finderAppPid = runningApps.first(where: { $0.bundleIdentifier == "com.apple.finder" })?.processIdentifier,
              let activeWindow = activeWindow,
              activeWindow.pid() == finderAppPid else {
            return false
        }
        
        return activeWindow.getWindows().first?.role() == "AXScrollArea"
    }
} 

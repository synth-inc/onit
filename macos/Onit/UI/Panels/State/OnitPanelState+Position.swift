//
//  OnitPanelState+Position.swift
//  Onit
//
//  Created by Kévin Naudin on 08/04/2025.
//

@preconcurrency import AppKit
import Foundation
import SwiftUI

extension OnitPanelState {
    
    // MARK: - Panel repositioning
    
    private var animationDuration: TimeInterval { 0.2 }
    
    @MainActor private func cancelCurrentAnimation() {
        currentAnimationTask?.cancel()
        currentAnimationTask = nil
    }
    
    func repositionPanel() {
        guard let window = trackedWindow?.element,
              let windowFrame = window.frame(),
              let panel = self.panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        
        if panel.isAnimating {
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
        
        let spaceOnRight = screenFrame.maxX - (position.x + size.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + TetherAppsManager.spaceBetweenWindows
        
        if hasEnoughSpace {
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
            if panel.isAnimating {
                return
            }
            if currentAnimationTask != nil {
                cancelCurrentAnimation()
            }
            
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
        panel.alphaValue = 1

        // Hide the existing UI before animating the panel in.
        self.animateChatView = true
        self.showChatView = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(toPanel, display: false)

            if let activeWindow = activeWindow, let fromActive = fromActive, let toActive = toActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration / 2)) {
                    self.animation(for: activeWindow, from: fromActive, to: toActive)
                }
            }
        } completionHandler: {
            self.animateChatView = true
            self.showChatView = true
            panel.isAnimating = false
            panel.wasAnimated = true
            panel.animatedFromLeft = abs(fromPanel.maxX - toPanel.minX) <= abs(fromPanel.maxX - toPanel.maxX)
        }
    }
    
    private func animateExit(
        activeWindow: AXUIElement?,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        toPanel: CGRect,
        steps: Int = 10
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        self.animateChatView = true
        self.showChatView = false
        
        if let activeWindow = activeWindow, let fromActive = fromActive, let toActive = toActive {
            self.animation(for: activeWindow, from: fromActive, to: toActive)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration / 2)) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = self.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                
                panel.animator().setFrame(toPanel, display: false)
            } completionHandler: {
                panel.hide()
                panel.isAnimating = false
                panel.alphaValue = 0
                self.panel = nil
            }
        }
    }
    
    private func animation(for activeWindow: AXUIElement, from: NSRect, to: NSRect) {
        cancelCurrentAnimation()
        let steps = 10
        let stepDuration = animationDuration / TimeInterval(steps)
        
        currentAnimationTask = Task { @MainActor in
            
            for step in 0...steps {
                if Task.isCancelled { break }
                
                let progress = Double(step) / Double(steps)
                let easedProgress = easeOutCubic(progress)
                
                let currentActiveWidth = from.width + (to.width - from.width) * easedProgress
                let currentActiveHeight = from.height + (to.height - from.height) * easedProgress
                let currentActiveX = from.origin.x + (to.origin.x - from.origin.x) * easedProgress
                let currentActiveY = from.origin.y + (to.origin.y - from.origin.y) * easedProgress
                let currentActiveFrame = CGRect(
                    x: currentActiveX,
                    y: currentActiveY,
                    width: currentActiveWidth,
                    height: currentActiveHeight
                )
                
                _ = activeWindow.setFrame(currentActiveFrame)
                
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
            
            if Task.isCancelled { return }
            currentAnimationTask = nil
        }
        
        func easeOutCubic(_ t: Double) -> Double {
            return 1 - pow(1 - t, 3)
        }
    }
    
    // MARK: - Thread-safe counter
    
    @preconcurrency
    private final class AtomicInt: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Int
        
        init(_ initialValue: Int) {
            self.value = initialValue
        }
        
        func increment() -> Int {
            lock.lock()
            defer { lock.unlock() }
            value += 1
            return value
        }
    }
} 

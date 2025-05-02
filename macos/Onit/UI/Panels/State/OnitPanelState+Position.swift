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
    
    func repositionPanel(action: TrackedWindowAction) {
        guard let window = trackedWindow?.element,
              let panel = self.panel,
              !panel.isAnimating,
              !panel.dragDetails.isDragging else {
            return
        }
        
        // Special case for Finder (desktop only)
        if window.isDesktopFinder {
            if let mouseScreen = NSScreen.mouse {
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
        
        let screen = action == .moveEnd ?
            NSScreen.mouse :
            window.getFrame(convertedToGlobalCoordinateSpace: true)?.findScreen()
        
        guard let windowFrame = window.getFrame(),
              let screen = screen,
              let rightmostScreen = NSScreen.rightmostScreen,
              let primaryScreenFrame = NSScreen.primary?.frame else { return }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // This is the height of the dock and/or toolbar.
        let activeScreenInset = screenFrame.height - visibleFrame.height
        let fullTop = primaryScreenFrame.height - screenFrame.height - visibleFrame.minY + activeScreenInset
        let windowDistanceFromTop = windowFrame.minY - fullTop
        
        let onitWidth = TetherAppsManager.minOnitWidth
        let onitHeight = min(windowFrame.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = visibleFrame.minY + (visibleFrame.height - windowFrame.height) - windowDistanceFromTop
        
        let spaceOnRight = screenFrame.maxX - (windowFrame.origin.x + windowFrame.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + TetherAppsManager.spaceBetweenWindows
        
        let isOnRightmostScreen = screen == rightmostScreen
        
        if (action == .move && !isOnRightmostScreen) || hasEnoughSpace {
            self.movePanel(screenFrame: screenFrame, onitWidth: onitWidth, onitHeight: onitHeight, onitY: onitY)
        } else {
            let minAppWidth = 500.0
            
            let maxAvailableWidth = screenFrame.maxX - windowFrame.origin.x - onitWidth - TetherAppsManager.spaceBetweenWindows
            
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
        if let panel = self.panel, !panel.isAnimating {
            
            if currentAnimationTask != nil {
                cancelCurrentAnimation()
            }
            
            if let window = trackedWindow?.element,
                let initialFrame = TetherAppsManager.shared.targetInitialFrames[window],
                let curFrame = window.getFrame() {

                // We only try to restore the window if it was resized
                if panel.resizedApplication {
                    print("Frames found, trying to set them back ")
                    fromActive = curFrame
                    
                    var newWidth = initialFrame.width

                    // We want to make sure that we don't expand the window beyond the screen width
                    if let screenFrame = window.getFrame(convertedToGlobalCoordinateSpace: true)?.findScreen()?.frame {
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
                }
                // We need to remove this everytime, to prevent saving old frames.
                // If we have old frames, we won't save the new ones.
                TetherAppsManager.shared.targetInitialFrames.removeValue(forKey: window)
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
    
    func tempHidePanel() {
        guard let panel = panel else { return }        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            panel.animator().alphaValue = 0.0
        }
    }

    func tempShowPanel() {
        guard let panel = panel else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            panel.animator().alphaValue = 1.0
        }
    }
    
    func showPanelForScreen() {
        guard let screen = trackedScreen,
              let panel = self.panel,
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
            x: screen.visibleFrame.maxX - TetherAppsManager.minOnitWidth,
            y: screen.visibleFrame.minY,
            width: TetherAppsManager.minOnitWidth,
            height: screen.visibleFrame.height
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
                         toPanel: newFrame)
        }
        
    }
    
    // MARK: - Layout
    
    private func movePanel(screenFrame: CGRect, onitWidth: CGFloat, onitHeight: CGFloat, onitY: CGFloat) {
        guard let window = trackedWindow?.element,
              let windowFrame = window.getFrame(),
              let panel = panel else {
            return
        }
        
        let fromFrame = NSRect(
            x: windowFrame.origin.x + windowFrame.width + TetherAppsManager.spaceBetweenWindows,
            y: onitY,
            width: 0,
            height: onitHeight
        )
        let newFrame = NSRect(
            x: windowFrame.origin.x + windowFrame.width + TetherAppsManager.spaceBetweenWindows,
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
              let windowFrame = window.getFrame(),
              let panel = panel else {
            return
        }
        
        let newAppX = screenFrame.maxX - windowFrame.width - onitWidth - TetherAppsManager.spaceBetweenWindows
        let yOffset = calculateYOffset(screenFrame: screenFrame, onitY: onitY)
        
        let activeWindowTargetRect = CGRect(
            x: newAppX,
            y: windowFrame.origin.y - yOffset,
            width: windowFrame.width,
            height: windowFrame.height
        )
        
        let newFrame = NSRect(
            x: newAppX + windowFrame.width + TetherAppsManager.spaceBetweenWindows,
            y: onitY + yOffset,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
            _ = window.setFrame(activeWindowTargetRect)
        } else {
            panel.resizedApplication = true
            let activeWindowSourceRect = CGRect(
                x: windowFrame.origin.x,
                y: windowFrame.origin.y,
                width: windowFrame.width,
                height: windowFrame.height
            )
            let fromFrame = NSRect(
                x: windowFrame.origin.x + windowFrame.width,
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
              let windowFrame = window.getFrame() else {
            return
        }
        
        let activeWindowTargetRect = CGRect(
            x: windowFrame.origin.x,
            y: windowFrame.origin.y,
            width: maxAvailableWidth,
            height: windowFrame.height
        )
        
        let newFrame = NSRect(
            x: windowFrame.origin.x + maxAvailableWidth + TetherAppsManager.spaceBetweenWindows,
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
                x: windowFrame.origin.x,
                y: windowFrame.origin.y,
                width: windowFrame.width,
                height: windowFrame.height
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
    
    private func calculateYOffset(screenFrame: CGRect, onitY: CGFloat) -> CGFloat {
        if onitY < screenFrame.minY {
            return screenFrame.minY - onitY
        }
        
        return 0
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
        guard !panel.isAnimating else { return }
        
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
        
        // Capture the window animation task (if applicable)
        var windowAnimationTask: Task<Void, Never>? = nil
        if let activeWindow = activeWindow, let fromActive = fromActive, let toActive = toActive {
            windowAnimationTask = self.animation(for: activeWindow, from: fromActive, to: toActive)
        }
        
        // Start an asynchronous block that waits for both animations to complete.
        Task { @MainActor in
            // Await the panel animation by wrapping it in a withCheckedContinuation.
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 2) {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = self.animationDuration
                        context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                        panel.animator().setFrame(toPanel, display: false)
                    } completionHandler: {
                        continuation.resume()
                    }
                }
            }
            
            // Await the window (active) animation if it was started.
            if let windowTask = windowAnimationTask {
                await windowTask.value
            }
            
            // Now that both animations have completed, execute the final code.
            panel.hide()
            panel.isAnimating = false
            panel.alphaValue = 0
            self.panel = nil
        }
    }
    
    @discardableResult
    private func animation(for activeWindow: AXUIElement, from: NSRect, to: NSRect) -> Task<Void, Never> {
        cancelCurrentAnimation()
        let steps = 10
        let stepDuration = animationDuration / TimeInterval(steps)
        
        let task = Task { @MainActor in
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
        
        currentAnimationTask = task
        return task
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

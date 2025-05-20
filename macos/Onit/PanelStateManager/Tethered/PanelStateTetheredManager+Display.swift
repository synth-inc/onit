//
//  PanelStateTetheredManager+Display.swift
//  Onit
//
//  Created by Kévin Naudin on 16/05/2025.
//

import AppKit
import Foundation

extension PanelStateTetheredManager {
    func showPanel(for state: OnitPanelState, action: TrackedWindowAction = .undefined) {
        guard let (trackedWindow, state) = statesByWindow.first(where: { $1 == state }),
              let panel = state.panel,
              !panel.isAnimating,
              !panel.dragDetails.isDragging else {
            return
        }
        
        let window = trackedWindow.element
        
        // Special case for Finder (desktop only)
        if window.isDesktopFinder {
            if let mouseScreen = NSScreen.mouse {
                let screenFrame = mouseScreen.frame
                let onitWidth = state.panelWidth
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
        
        let onitWidth = state.panelWidth
        let onitHeight = min(windowFrame.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = visibleFrame.minY + (visibleFrame.height - windowFrame.height) - windowDistanceFromTop
        
        let spaceOnRight = screenFrame.maxX - (windowFrame.origin.x + windowFrame.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + PanelStateBaseManager.spaceBetweenWindows
        
        let isOnRightmostScreen = screen == rightmostScreen
        
        if (action == .move && !isOnRightmostScreen) || hasEnoughSpace {
            movePanel(state: state,
                      window: window,
                      screenFrame: screenFrame,
                      onitWidth: onitWidth,
                      onitHeight: onitHeight,
                      onitY: onitY)
        } else {
            
            let maxAvailableWidth = screenFrame.maxX - windowFrame.origin.x - onitWidth - PanelStateBaseManager.spaceBetweenWindows
            
            if maxAvailableWidth >= OnitRegularPanel.minAppWidth {
                resizeWindowAndMovePanel(state: state,
                                         window: window,
                                         onitWidth: onitWidth,
                                         onitHeight: onitHeight,
                                         onitY: onitY,
                                         maxAvailableWidth: maxAvailableWidth)
            } else {
                moveWindowAndPanel(state: state,
                                   window: window,
                                   screenFrame: screenFrame,
                                   onitWidth: onitWidth,
                                   onitHeight: onitHeight,
                                   onitY: onitY)
            }
        }
    }
    
    func hidePanel(for state: OnitPanelState) {
        guard let (trackedWindow, state) = statesByWindow.first(where: { $1 == state }),
              let panel = state.panel,
              !panel.isAnimating else {
            return
        }
        
        if state.currentAnimationTask != nil {
            state.cancelCurrentAnimation()
        }
        
        let window = trackedWindow.element
        var fromActive : NSRect? = nil
        var toActive: NSRect? = nil
        
        if let initialFrame = targetInitialFrames[window], let curFrame = window.getFrame() {
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
            targetInitialFrames.removeValue(forKey: window)
        }

        let toPanel: NSRect
        if panel.animatedFromLeft {
            toPanel = NSRect(origin: panel.frame.origin, size: NSSize(width: 1, height: panel.frame.height))
        } else {
            let toPanelX = panel.frame.maxX - 2
            toPanel = NSRect(origin: NSPoint(x: toPanelX, y: panel.frame.minY), size: NSSize(width: 1, height: panel.frame.height))
        }
        
        animateExit(
            state: state,
            activeWindow: window,
            fromActive: fromActive,
            toActive: toActive,
            panel: panel,
            toPanel: toPanel
        )
    }
    
    func tempHidePanel(state: OnitPanelState) {
        guard let panel = state.panel else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            panel.animator().alphaValue = 0.0
        }
    }

    func tempShowPanel(state: OnitPanelState) {
        guard let panel = state.panel else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            panel.animator().alphaValue = 1.0
        }
    }
    
    private func movePanel(
        state: OnitPanelState,
        window: AXUIElement,
        screenFrame: CGRect,
        onitWidth: CGFloat,
        onitHeight: CGFloat,
        onitY: CGFloat
    ) {
        guard let windowFrame = window.getFrame(), let panel = state.panel else {
            return
        }
        
        let fromFrame = NSRect(
            x: windowFrame.origin.x + windowFrame.width + PanelStateBaseManager.spaceBetweenWindows,
            y: onitY,
            width: 0,
            height: onitHeight
        )
        let newFrame = NSRect(
            x: windowFrame.origin.x + windowFrame.width + PanelStateBaseManager.spaceBetweenWindows,
            y: onitY,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: false)
        } else {
            panel.resizedApplication = false
            animateEnter(state: state,
                         activeWindow: nil,
                         fromActive: nil,
                         toActive: nil,
                         panel: panel,
                         fromPanel: fromFrame,
                         toPanel: newFrame
            )
        }
    }
    
    private func moveWindowAndPanel(
        state: OnitPanelState,
        window: AXUIElement,
        screenFrame: CGRect,
        onitWidth: CGFloat,
        onitHeight: CGFloat,
        onitY: CGFloat
    ) {
        guard let windowFrame = window.getFrame(), let panel = state.panel else {
            return
        }
        
        let newAppX = screenFrame.maxX - windowFrame.width - onitWidth - PanelStateBaseManager.spaceBetweenWindows
        let yOffset = onitY < screenFrame.minY ? screenFrame.minY - onitY : 0
        
        let activeWindowTargetRect = CGRect(
            x: newAppX,
            y: windowFrame.origin.y - yOffset,
            width: windowFrame.width,
            height: windowFrame.height
        )
        
        let newFrame = NSRect(
            x: newAppX + windowFrame.width + PanelStateBaseManager.spaceBetweenWindows,
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
                state: state,
                activeWindow: window,
                fromActive: activeWindowSourceRect,
                toActive: activeWindowTargetRect,
                panel: panel,
                fromPanel: fromFrame,
                toPanel: newFrame
            )
        }
    }
    
    private func resizeWindowAndMovePanel(
        state: OnitPanelState,
        window: AXUIElement,
        onitWidth: CGFloat,
        onitHeight: CGFloat,
        onitY: CGFloat,
        maxAvailableWidth: CGFloat
    ) {
        guard let windowFrame = window.getFrame(), let panel = state.panel else {
            return
        }
        
        let activeWindowTargetRect = CGRect(
            x: windowFrame.origin.x,
            y: windowFrame.origin.y,
            width: maxAvailableWidth,
            height: windowFrame.height
        )
        
        let newFrame = NSRect(
            x: windowFrame.origin.x + maxAvailableWidth + PanelStateBaseManager.spaceBetweenWindows,
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
                state: state,
                activeWindow: window,
                fromActive: activeWindowSourceRect,
                toActive: activeWindowTargetRect,
                panel: panel,
                fromPanel: fromFrame,
                toPanel: newFrame
            )
        }
    }
    
    private func animateEnter(
        state: OnitPanelState,
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
        state.animateChatView = true
        state.showChatView = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(toPanel, display: false)

            if let activeWindow = activeWindow, let fromActive = fromActive, let toActive = toActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration / 2)) {
                    self.animation(state: state, window: activeWindow, from: fromActive, to: toActive)
                }
            }
        } completionHandler: {
            state.animateChatView = true
            state.showChatView = true
            panel.isAnimating = false
            panel.wasAnimated = true
            panel.animatedFromLeft = abs(fromPanel.maxX - toPanel.minX) <= abs(fromPanel.maxX - toPanel.maxX)
        }
    }
    
    private func animateExit(
        state: OnitPanelState,
        activeWindow: AXUIElement?,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        toPanel: CGRect,
        steps: Int = 10
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        state.animateChatView = true
        state.showChatView = false
        
        // Start an asynchronous block that waits for both animations to complete.
        Task { @MainActor in
            // Capture the window animation task (if applicable)
            var windowAnimationTask: Task<Void, Never>? = nil
            if let activeWindow = activeWindow, let fromActive = fromActive, let toActive = toActive {
                windowAnimationTask = self.animation(state: state, window: activeWindow, from: fromActive, to: toActive)
            }
            
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
            state.panel = nil
        }
    }
    
    @discardableResult
    private func animation(state: OnitPanelState, window: AXUIElement, from: NSRect, to: NSRect) -> Task<Void, Never> {
        state.cancelCurrentAnimation()
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
                
                _ = window.setFrame(currentActiveFrame)
                
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
            
            if Task.isCancelled { return }
            state.currentAnimationTask = nil
        }
        
        func easeOutCubic(_ t: Double) -> Double {
            return 1 - pow(1 - t, 3)
        }
        
        state.currentAnimationTask = task
        return task
    }
}

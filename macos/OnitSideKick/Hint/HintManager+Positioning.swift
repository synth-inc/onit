//
//  HintManager+Positioning.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions: Reset Positions
 * Public Functions: Hint Reposition
 * Public Functions: More Menu Resposition
 */

import AppKit
import Defaults

extension HintManager {
    // MARK: - Public Functions: Reset Positions

    func resetPositions() {
        Defaults[.hintYPositionByApp].removeAll()
        Defaults[.hintYPositionForPinnedMode] = nil
        Defaults[.hintYPositionForUntetheredModeScreens].removeAll()
        lastYComputed = nil
    }
    
    // MARK: - Public Functions: Hint Reposition
    
    /// Reposition window to stay anchored to the right edge when content size changes.
    /// Uses mode-aware anchoring:
    ///     Tethered Mode: Anchors to the edge of the app window.
    ///     Pinned/Untethered Modes: Anchors to the edge of the screen.
    func repositionHintToRightEdge() {
        guard let screen = currentScreen ?? hintWindow.screen ?? NSScreen.main
        else {
            return
        }

        /// Determine anchor point based on mode.
        ///     In Tethered mode, `trackedWindow` is set — anchor to the window's right edge.
        ///     In Pinned/Untethered modes, `trackedWindow` is nil — anchor to the screen's right edge.
        let anchorX: CGFloat

        /// Tethered Mode
        if let trackedWindow = currentPanelState?.trackedWindow?.element,
           let windowFrame = trackedWindow.getFrame(convertedToGlobalCoordinateSpace: true)
        {
            anchorX = windowFrame.maxX
        }
        /// Pinned/Untethered Modes
        else {
            anchorX = screen.visibleFrame.maxX
        }

        var hintWindowFrame = hintWindow.frame
        
        /// Setting x-position anchor to right edge.
        hintWindowFrame.origin.x = anchorX - hintWindowFrame.width

        /// Ensure we don't go off the left edge of the screen.  Allows hint positioning to be multi-monitor aware, preventing bleeding across monitors.
        let screenMinX = screen.visibleFrame.minX
        if hintWindowFrame.origin.x < screenMinX {
            hintWindowFrame.origin.x = screenMinX
        }

        hintWindow.setFrame(hintWindowFrame, display: true)

        repositionMoreMenuIfNeeded()
    }
    
    // MARK: - Public Functions: More Menu Reposition

    func repositionMoreMenuIfNeeded(
        shouldAnimateIn: Bool = false,
        isInitialShow: Bool = false
    ) {
        guard isInitialShow || moreMenuWindowIsVisible else { return }
        guard let moreMenuWindow = self.moreMenuWindow else { return }

        /// Force layout update before measuring to ensure accurate Hint window dimensions.
        hintWindow.contentView?.layoutSubtreeIfNeeded()

        let hintWindowFrame: CGRect
        
        /// Get Hint window dimensions directly from the injected SwiftUI view.
        if let fittingSize = hintWindow.contentView?.fittingSize {
            let expectedMinX = hintWindow.frame.maxX - fittingSize.width
            hintWindowFrame = CGRect(
                x: expectedMinX,
                y: hintWindow.frame.origin.y,
                width: fittingSize.width,
                height: fittingSize.height
            )
        }
        /// Otherwise, fall back to getting the dimensions from the Hint window's built-in frame.
        else {
            hintWindowFrame = hintWindow.frame
        }
        
        let moreMenuWindowWidth: CGFloat
        let moreMenuWindowHeight: CGFloat
        
        /// Force layout update before measuring to ensure accurate More Menu dimensions.
        moreMenuWindow.contentView?.layoutSubtreeIfNeeded()

        /// Get more menu window dimensions from injected SwiftUI view.
        if let fittingSize = moreMenuWindow.contentView?.fittingSize {
            moreMenuWindowWidth = fittingSize.width
            moreMenuWindowHeight = fittingSize.height
        }
        /// Otherwise, fall back to getting current more menu window's dimensions.
        else {
            moreMenuWindowWidth = moreMenuWindow.frame.width
            moreMenuWindowHeight = moreMenuWindow.frame.height
        }

        /// Position menu 8px to the left of the hint window.
        var finalX = hintWindowFrame.minX - moreMenuWindowWidth - Hint.contentSpacing

        /// Ensure menu doesn't go off-screen to the left.
        if let screen = currentScreen ?? hintWindow.screen ?? NSScreen.main {
            let minX = screen.visibleFrame.minX
            if finalX < minX {
                finalX = minX
            }
        }

        /// Keep vertical center aligned with Hint, clamping to screen bounds by anchoring to Hint edges.
        var finalY = hintWindowFrame.midY - moreMenuWindowHeight / 2

        if let screen = currentScreen ?? hintWindow.screen ?? NSScreen.main {
            let screenMinY = screen.visibleFrame.minY
            let screenMaxY = screen.visibleFrame.maxY

            /// Align the More Menu's bottom edge with the Hint's bottom edge if there is no room below the screen.
            if finalY < screenMinY {
                finalY = hintWindowFrame.minY
            }
            
            /// Align the More Menu's top edge with the Hint's top edge if there is no room above the screen.
            if finalY + moreMenuWindowHeight > screenMaxY {
                finalY = hintWindowFrame.maxY - moreMenuWindowHeight
            }
        }

        if shouldAnimateIn {
            showMoreMenuAnimatedIn(
                moreMenuWindow: moreMenuWindow,
                finalX: finalX,
                finalY: finalY,
                moreMenuWindowWidth: moreMenuWindowWidth,
                moreMenuWindowHeight: moreMenuWindowHeight,
                isInitialShow: isInitialShow
            )
        } else {
            showMoreMenuImmediately(
                moreMenuWindow: moreMenuWindow,
                finalX: finalX,
                finalY: finalY,
                moreMenuWindowWidth: moreMenuWindowWidth,
                moreMenuWindowHeight: moreMenuWindowHeight,
                isInitialShow: isInitialShow
            )
        }
    }
    
    private func showMoreMenuAnimatedIn(
        moreMenuWindow: NSWindow,
        finalX: CGFloat,
        finalY: CGFloat,
        moreMenuWindowWidth: CGFloat,
        moreMenuWindowHeight: CGFloat,
        isInitialShow: Bool
    ) {
        /// Start animation at 8px to the right of the final position for the animate-in.
        let startX = finalX + Hint.contentSpacing
        
        /// Start frame.
        moreMenuWindow.setFrame(
            NSRect(
                x: startX,
                y: finalY,
                width: moreMenuWindowWidth,
                height: moreMenuWindowHeight
            ),
            display: true
        )
        moreMenuWindow.alphaValue = 0
        
        if isInitialShow {
            moreMenuWindow.orderFront(nil)
        }

        /// Animate more menu to slide in.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            /// Final frame.
            moreMenuWindow.animator().setFrame(
                NSRect(
                    x: finalX,
                    y: finalY,
                    width: moreMenuWindowWidth,
                    height: moreMenuWindowHeight
                ),
                display: true
            )
            moreMenuWindow.animator().alphaValue = 1
        }
    }
    
    private func showMoreMenuImmediately(
        moreMenuWindow: NSWindow,
        finalX: CGFloat,
        finalY: CGFloat,
        moreMenuWindowWidth: CGFloat,
        moreMenuWindowHeight: CGFloat,
        isInitialShow: Bool
    ) {
        moreMenuWindow.setFrame(
            NSRect(
                x: finalX,
                y: finalY,
                width: moreMenuWindowWidth,
                height: moreMenuWindowHeight
            ),
            display: true
        )
        
        if isInitialShow {
            moreMenuWindow.orderFront(nil)
        }
    }
}

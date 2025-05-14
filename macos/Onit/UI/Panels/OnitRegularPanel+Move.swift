//
//  OnitRegularPanel+Move.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

import Foundation
import SwiftUI

extension OnitRegularPanel {
    
    @objc func windowDidMove(_ notification: Notification) {
        guard let activeWindow = state.trackedWindow?.element,
              let activeWindowFrame = activeWindow.getFrame(),
              wasAnimated, !isAnimating, dragDetails.isDragging, !state.isWindowDragging else { return }
        
        log.error("windowDidMove")
        let currentPosition = adjustPanelIfBeyondRightScreenEdge()

        if currentPosition != dragDetails.lastPosition {
            
            let deltaX: CGFloat
            if dragDetails.lastPosition == .zero {
                let expectedX = activeWindowFrame.origin.x + activeWindowFrame.width - (TetheredButton.width / 2)
                deltaX = currentPosition.x - expectedX
            } else {
                deltaX = currentPosition.x - dragDetails.lastPosition.x
            }
            let newX = activeWindowFrame.origin.x + deltaX
            var newY = activeWindowFrame.origin.y
            
            if let primaryScreen = NSScreen.primary, let screen = screen {
                let primaryScreenHeight = primaryScreen.frame.height
                let screenOriginY = screen.frame.origin.y
                let onitRelativeY = currentPosition.y - screenOriginY
                let distanceFromScreenTop = screen.frame.height - onitRelativeY - frame.height
                
                if screen === primaryScreen {
                    newY = distanceFromScreenTop
                } else {
                    let heightDifference = screen.frame.height - primaryScreenHeight
                    
                    newY = -screenOriginY + distanceFromScreenTop - heightDifference
                }
            }
            
            _ = activeWindow.setPosition(NSPoint(x: newX, y: newY))
            
            dragDetails.lastPosition = currentPosition
        }
    }
    
    func panelResizeEnded(originalPanelWidth: CGFloat) {
        guard wasAnimated, !isAnimating, !state.isWindowDragging else { return }

        // Check if pinned mode is enabled
        let usePinnedMode = FeatureFlagManager.shared.usePinnedMode
        
        if state.isScreenMode && usePinnedMode {
            // In pinned mode, we need to resize all windows that overlap with the panel
            if let screen = state.trackedScreen ?? NSScreen.mouse,
               let pinnedManager = PanelStateCoordinator.shared.currentManager as? PanelStatePinnedManager {
                pinnedManager.resizeWindows(for: screen, isPanelResized: true)
            }
        } else {
            // Normal mode - adjust a single active window
            guard let activeWindow = state.trackedWindow?.element,
                  let activeWindowFrame = activeWindow.getFrame() else { return }
                  
            // Adjust the active window's width to match the panel's new width
            let deltaWidth = self.width - originalPanelWidth        
            if deltaWidth != 0 {
                // There's an edge case where window's are non-resizable (for example VoiceOver Utility)
                // We need to check if the window is resizable before attempting to resize it
                var isSettable: DarwinBoolean = false
                let settableResult = AXUIElementIsAttributeSettable(activeWindow, kAXSizeAttribute as CFString, &isSettable)

                if isSettable.boolValue {
                    // If the window is resizeable then we should resize it
                    let newWidth = round(activeWindowFrame.width - deltaWidth)
                    let newFrame = NSRect(
                        x: activeWindowFrame.origin.x,
                        y: activeWindowFrame.origin.y,
                        width: newWidth,
                        height: activeWindowFrame.height
                    )
                    _ = activeWindow.setFrame(newFrame)
                } else {
                    // If the window is not resizeable then we should move it's position but not change it's size. 
                   let newX = round(activeWindowFrame.origin.x - deltaWidth)
                   let newPosition = NSPoint(x: newX, y: activeWindowFrame.origin.y)
                   _ = activeWindow.setPosition(newPosition)
                }       
            }
        }
    }
    
    private func adjustPanelIfBeyondRightScreenEdge() -> CGPoint {
        guard let rightmostScreen = NSScreen.rightmostScreen,
              frame.origin.x + frame.width > rightmostScreen.visibleFrame.maxX else {
            return frame.origin
        }
        
        let newOrigin = CGPoint(x: rightmostScreen.visibleFrame.maxX - frame.width, y: frame.origin.y)
        
        setFrameOrigin(newOrigin)
        
        return newOrigin
    }
}

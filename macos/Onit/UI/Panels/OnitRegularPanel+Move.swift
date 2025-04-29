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
        if isResizing { return }
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
        guard let activeWindow = state.trackedWindow?.element,
              let activeWindowFrame = activeWindow.getFrame(),
              wasAnimated, !isAnimating, dragDetails.isDragging, !state.isWindowDragging else { return }

        // Get the screen that contains the active window
        guard let activeWindowFrame = activeWindow.getFrame(convertedToGlobalCoordinateSpace: true),
              let activeWindowScreen = activeWindowFrame.findScreen() else {
            return
        }
        
        
        // Adjust the active window's width to match the panel's new width
        let currentPosition = frame.origin
        let deltaWidth = self.width - originalPanelWidth
        
        if deltaWidth != 0 {
            let newWidth = activeWindowFrame.width - deltaWidth
            if newWidth >= OnitRegularPanel.minAppWidth {
                let newFrame = NSRect(
                    x: activeWindowFrame.origin.x,
                    y: activeWindowFrame.origin.y,
                    width: newWidth,
                    height: activeWindowFrame.height
                )
                _ = activeWindow.setFrame(newFrame)
            } else {
                // If we've gone below the minimum app width, then bump the ActiveWindow to the left
                let newFrame = NSRect(
                    x: activeWindowFrame.origin.x - (OnitRegularPanel.minAppWidth - newWidth),
                    y: activeWindowFrame.origin.y,
                    width: OnitRegularPanel.minAppWidth,
                    height: activeWindowFrame.height
                )
                _ = activeWindow.setFrame(newFrame)
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

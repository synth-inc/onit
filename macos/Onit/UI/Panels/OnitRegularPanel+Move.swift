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
            dragDetails.dragEndTimer?.invalidate()
            dragDetails.dragEndTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                Task { @MainActor in
                    self.dragDetails = .init()
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

//
//  CGRect+Converter.swift
//  Onit
//
//  Created by Kévin Naudin on 09/23/2025.
//

import AppKit
import Foundation

extension CGRect {
    func toMacOSCoordinates() -> CGRect {
        guard let mainScreen = NSScreen.primary else {
            return self
        }
        
        let screenHeight = mainScreen.frame.height
        let convertedY = screenHeight - self.origin.y - self.height
        
        return CGRect(
            x: self.origin.x,
            y: convertedY,
            width: self.width,
            height: self.height
        )
    }

    /// Adjusts the rect to fit within the visible screen area
    /// Used by hint windows to ensure they stay visible on screen
    func adjustedToFitScreen(padding: CGFloat = 8) -> CGRect {
        guard let screen = NSScreen.main else { return self }

        var adjustedFrame = self
        let screenFrame = screen.visibleFrame

        // Adjust horizontal position
        if adjustedFrame.maxX > screenFrame.maxX - padding {
            adjustedFrame.origin.x = screenFrame.maxX - adjustedFrame.width - padding
        }
        if adjustedFrame.minX < screenFrame.minX + padding {
            adjustedFrame.origin.x = screenFrame.minX + padding
        }

        // Adjust vertical position
        if adjustedFrame.maxY > screenFrame.maxY - padding {
            adjustedFrame.origin.y = screenFrame.maxY - adjustedFrame.height - padding
        }
        if adjustedFrame.minY < screenFrame.minY + padding {
            adjustedFrame.origin.y = screenFrame.minY + padding
        }

        return adjustedFrame
    }

    /// Adjusts the rect to fit within a reference window's bounds
    /// Used by hint windows to ensure they stay visible within the parent window area
    func adjustedToFitWindow(_ window: NSWindow?, padding: CGFloat = 8) -> CGRect {
        guard let window = window else {
            return adjustedToFitScreen(padding: padding)
        }

        var adjustedFrame = self
        let windowFrame = window.frame

        // Adjust horizontal position to stay within window bounds
        if adjustedFrame.maxX > windowFrame.maxX - padding {
            adjustedFrame.origin.x = windowFrame.maxX - adjustedFrame.width - padding
        }
        if adjustedFrame.minX < windowFrame.minX + padding {
            adjustedFrame.origin.x = windowFrame.minX + padding
        }

        // Keep vertical adjustment relative to screen (hint appears above selection)
        // but ensure it doesn't go off screen
        return adjustedFrame.adjustedToFitScreen(padding: padding)
    }
}

//
//  NSRect+Screen.swift
//  Onit
//
//  Created by Kévin Naudin on 14/03/2025.
//

import AppKit

extension NSRect {
    
    func dominantScreen() -> NSScreen? {
        var maxIntersectionArea: CGFloat = 0
        var bestScreen: NSScreen?

        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(self)
            let area = intersection.width * intersection.height

            if area > maxIntersectionArea {
                maxIntersectionArea = area
                bestScreen = screen
            }
        }

        return bestScreen
    }
    
    func findScreen() -> NSScreen? {
        guard let mainScreen = NSScreen.main else {
            return nil
        }
        let matchingScreen = NSScreen.screens
            .filter({ $0 == mainScreen })
            .first(where: { origin.x >= $0.frame.minX && origin.x < $0.frame.maxX })
        
        if origin.y < 0 || origin.y > mainScreen.frame.maxY ||
            origin.x < 0 || origin.x >= mainScreen.frame.maxX {
            if let matchingScreen = matchingScreen {
                return matchingScreen
            }
        }
        
        return mainScreen
    }
    
    func calculateWindowDistanceFromBottom() -> CGFloat? {
        guard let activeScreen = dominantScreen() else { return nil }
        
        // Find the primary screen (the one with origin at 0,0)
        let screens = NSScreen.screens
        let primaryScreen = NSScreen.primary ?? NSScreen.main ?? screens.first!
        
        // VisibleFrame subtracts the dock and toolbar. Frame is the whole screen.
        let activeScreenFrame = activeScreen.frame
        let activeScreenVisibileFrame = activeScreen.visibleFrame
        let primaryScreenFrame = primaryScreen.frame
        
        // This is the height of the dock and/or toolbar.
        let activeScreenInset = activeScreenFrame.height - activeScreenVisibileFrame.height
        
        // This is the maximum possible Y value a window can occupy on a given screen.
        let fullTop = primaryScreenFrame.height - activeScreenFrame.height - activeScreenVisibileFrame.minY + activeScreenInset
        
        // This is how far down the window is from the max possibile position.
        let windowDistanceFromTop = minY - fullTop
        return activeScreenVisibileFrame.minY + (activeScreenVisibileFrame.height - height) - windowDistanceFromTop
    }
}

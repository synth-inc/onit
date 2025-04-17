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
        let matchingScreen = NSScreen.screens.max { (screen1, screen2) -> Bool in
            let intersection1 = screen1.frame.intersection(self)
            let intersection2 = screen2.frame.intersection(self)
            return intersection1.width * intersection1.height < intersection2.width * intersection2.height
        }
        
        return matchingScreen ?? NSScreen.main
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

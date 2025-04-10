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
}

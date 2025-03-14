//
//  NSRect+Screen.swift
//  Onit
//
//  Created by Kévin Naudin on 14/03/2025.
//

import AppKit

extension NSRect {
    
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

//
//  NSRect+Screen.swift
//  Onit
//
//  Created by Kévin Naudin on 14/03/2025.
//

import AppKit

extension NSRect {

    func findScreen() -> NSScreen? {
        let matchingScreen = NSScreen.screens.max { (screen1, screen2) -> Bool in
            let intersection1 = screen1.frame.intersection(self)
            let intersection2 = screen2.frame.intersection(self)
            
            return intersection1.width * intersection1.height < intersection2.width * intersection2.height
        }
        
        if matchingScreen == nil {
            log.error("Cannot find screen for rect: \(self)")
        }
        
        return matchingScreen ?? NSScreen.main
    }
    
}

//
//  CGContext+Draw.swift
//  Onit
//
//  Created by Kévin Naudin on 23/09/2025.
//

import AppKit

extension CGContext {
    
    func drawAttributedString(_ text: NSAttributedString, point: CGPoint) {
        saveGState()
        
        let nsContext = NSGraphicsContext(cgContext: self, flipped: false)
        let previousContext = NSGraphicsContext.current
        
        NSGraphicsContext.current = nsContext
        
        let textRect = CGRect(x: point.x, y: point.y, width: 100, height: 20)
        
        text.draw(in: textRect)
        
        NSGraphicsContext.current = previousContext
        
        restoreGState()
    }
}

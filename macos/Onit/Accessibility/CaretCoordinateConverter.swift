//
//  CaretCoordinateConverter.swift
//  Onit
//
//  Created by Kévin Naudin on 06/06/2025.
//

import ApplicationServices
import Foundation

struct CaretCoordinateConverter {
    
    // MARK: - Public Functions
    
    static func convertToScreenCoordinates(_ rect: CGRect, fromElement element: AXUIElement) -> CGRect {
        if rect.origin.x <= 10 {
            return convertWindowRelativeCoordinates(rect, fromElement: element)
        }
        
        return centerCaretCoordinates(rect)
    }
    
    // MARK: - Private Functions
    
    private static func centerCaretCoordinates(_ rect: CGRect) -> CGRect {
        let centeredY = rect.height > 0 ? rect.origin.y + (rect.height / 2) : rect.origin.y
        
        return CGRect(
            x: rect.origin.x,
            y: centeredY,
            width: max(rect.width, 2),
            height: max(rect.height, 20)
        )
    }
    
    private static func convertWindowRelativeCoordinates(_ rect: CGRect, fromElement element: AXUIElement) -> CGRect {
        guard let pid = element.pid(),
              let window = pid.firstMainWindow,
              let windowFrame = window.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return centerCaretCoordinates(rect)
        }
        
        let windowRelativeRect = CGRect(
            x: windowFrame.origin.x + rect.origin.x,
            y: windowFrame.origin.y + rect.origin.y,
            width: rect.width,
            height: rect.height
        )
        
        return centerCaretCoordinates(windowRelativeRect)
    }
} 

//
//  RoundedLeftCorners.swift
//  Onit
//
//  Created by Kévin Naudin on 03/04/2025.
//

import SwiftUI

struct RoundedLeftCorners: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from bottom right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Line to bottom left corner
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        
        // Bottom left rounded corner
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                   radius: radius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(180),
                   clockwise: false)
        
        // Line up the left side
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        
        // Top left rounded corner
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                   radius: radius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(270),
                   clockwise: false)
        
        // Complete the shape
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}

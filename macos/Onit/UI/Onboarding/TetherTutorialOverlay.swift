//
//  TetherTutorialOverlay.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/25/25.
//

import Defaults
import SwiftUI

struct TetherTutorialOverlay: View {

    static let width: CGFloat = 250
    static let height: CGFloat = 84
    @State private var fadeIn = false
    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Text("Welcome to Onit")
                    .styleText(size: 19, weight: .medium)
                Text("Click to start")
                    .styleText(size: 12, color: .gray200)
            }
            .padding([.top, .bottom, .leading], 20)
            .padding(.trailing, 40)
            .background(TutorialShape().fill(.gray700))
            .overlay(TutorialShape().stroke(Color.gray500, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
            .frame(width: TetherTutorialOverlay.width, height: TetherTutorialOverlay.height, alignment: .center)
            Spacer()
        }
        .opacity(fadeIn ? 1 : 0)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                fadeIn = true
            }
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                scale = 1
            }
        }
    }
}

struct TutorialShape: Shape {
    func path(in rect: CGRect) -> Path {
        // The pointer is defined from a square of 15x15, so calculate half its diagonal component.
        let pointerSquareSize: CGFloat = 15.0
        let pointerHeight = sqrt(pow(pointerSquareSize, 2) * 2) // Pythagoras would be proud
        let pointerWidth = sqrt(pow(pointerSquareSize, 2) - pow(pointerHeight / 2, 2))
        var path = Path()
        // Create the bubble rect by excluding the pointer area.
        let bubbleRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width - pointerWidth,
            height: rect.height
        )
        
        let cornerRadius: CGFloat = 14
        let midY = bubbleRect.midY
        
        // Calculate triangle points
        let triangleTop = CGPoint(x: bubbleRect.maxX, y: midY - pointerHeight / 2)
        let triangleTip = CGPoint(x: rect.maxX, y: midY)
        let triangleBottom = CGPoint(x: bubbleRect.maxX, y: midY + pointerHeight / 2)
        
        // Start at the top-right corner of the rounded rectangle
        path.move(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY))
        
        // Top-left corner
        path.addArc(
            center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 180),
            clockwise: true
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY - cornerRadius))
        
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 90),
            clockwise: true
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY))
        
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 0),
            clockwise: true
        )
        
        // Right edge up to triangle
        path.addLine(to: triangleBottom)
        
        // Draw the triangle
        path.addLine(to: triangleTip)
        path.addLine(to: triangleTop)
        
        // Complete the path back to the starting point
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY + cornerRadius))
        
        // Top-right corner
        path.addArc(
            center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: -90),
            clockwise: true
        )
        
        path.closeSubpath()
        return path
    }
}

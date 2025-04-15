//
//  ViewStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

extension View {
    func addBorderRadius(
        cornerRadius: CGFloat = 12,
        inset: CGFloat = 0.5,
        stroke: Color = Color.gray500,
        lineWidth: CGFloat = 1
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: inset)
                    .stroke(stroke, lineWidth: lineWidth)
            )
    }

    func addShadow(
        color: Color = Color.black.opacity(0.8),
        radius: CGFloat = 5.5,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    func addAnimation<Value: Equatable>(
        value: Binding<Value>
    ) -> some View {
        self.animation(
            .easeIn(duration: animationDuration),
            value: value.wrappedValue
        )
    }
    
    func truncateText() -> some View {
        self.lineLimit(1).truncationMode(.tail)
    }
}

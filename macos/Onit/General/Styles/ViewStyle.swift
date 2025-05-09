//
//  ViewStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

// MARK: - General View Styles

struct GradientBorder {
    var colorOne: Color = Color.white
    var colorTwo: Color = Color.white
}

struct DefaultBorderValues {
    var cornerRadius: CGFloat = 12
    var inset: CGFloat = 0.5
    var lineWidth: CGFloat = 1
}

extension View {
    func addBorder(
        cornerRadius: CGFloat = DefaultBorderValues().cornerRadius,
        inset: CGFloat = DefaultBorderValues().inset,
        lineWidth: CGFloat = DefaultBorderValues().lineWidth,
        stroke: Color = Color.gray500
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: inset)
                    .stroke(stroke, lineWidth: lineWidth)
            )
            .cornerRadius(cornerRadius)
    }
    
    func addGradientBorder(
        cornerRadius: CGFloat = DefaultBorderValues().cornerRadius,
        inset: CGFloat = DefaultBorderValues().inset,
        lineWidth: CGFloat = DefaultBorderValues().lineWidth,
        gradientBorder: GradientBorder = GradientBorder()
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: inset)
                    .stroke(
                        LinearGradient(
                            gradient:
                                Gradient(colors: [
                                    gradientBorder.colorOne,
                                    gradientBorder.colorTwo
                                ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
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
    
    func preventInteraction() -> some View {
        self.allowsHitTesting(false)
    }
}

// MARK: - Text Styles

extension View {
    func styleText(
        size: CGFloat = 14,
        weight: Font.Weight = Font.Weight.medium,
        color: Color = Color.primary,
        align: TextAlignment = TextAlignment.leading
    ) -> some View {
        self
            .font(.system(
                size: size, weight: weight
            ))
            .foregroundColor(color)
            .multilineTextAlignment(align)
    }
    
    func truncateText() -> some View {
        self.lineLimit(1).truncationMode(.tail)
    }
}

//
//  LoadingOverlay.swift
//  Onit
//
//  Created by Kévin Naudin on 02/02/2025.
//

import SwiftUI

public struct LoadingOverlayModifier: ViewModifier {
    public var amount: Int
    public var done: Bool

    var degrees: Double {
        done ? 360 : Double(amount) / 100 * 360
    }

    var padding: Double {
        done ? -0.25 : 0.25
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                Color.black.opacity(0.5)
                    .mask {
                        PieSlice(
                            startAngle: .degrees(-90),
                            endAngle: .degrees(Double(-90 + degrees)),
                            padding: padding
                        )
                        .fill(style: FillStyle(eoFill: true))
                    }

            }
            .animation(.spring, value: degrees)
            .animation(.spring, value: padding)
    }
}

struct PieSlice: Shape {
    var startAngle: Angle = .zero
    var endAngle: Angle
    var padding: CGFloat = .zero

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, CGFloat> {
        get {
            AnimatablePair(AnimatablePair(startAngle.radians, endAngle.radians), padding)
        }
        set {
            startAngle = .radians(newValue.first.first)
            endAngle = .radians(newValue.first.second)
            padding = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let effectiveRadius = radius * (1 - padding * 2)

        path.move(to: center)
        path.addArc(
            center: center,
            radius: effectiveRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false)
        path.closeSubpath()

        return path
    }
}

extension View {
    public func loadingOverlay(_ amount: Int, done: Bool) -> some View {
        modifier(LoadingOverlayModifier(amount: amount, done: done))
    }
}

// MARK: Preview

#Preview {
    Color.red
        .frame(width: 100, height: 100)
        .loadingOverlay(40, done: true)
}

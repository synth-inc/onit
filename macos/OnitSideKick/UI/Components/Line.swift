//
//  Line.swift
//  Onit
//
//  Created by Loyd Kim on 3/25/26.
//

import SwiftUI

struct Line: View {
    var color: Color
    var height: CGFloat = 1
    var dottedDash: [CGFloat] = [1, 2]
    var isDotted: Bool = false

    var body: some View {
        LineShape()
            .stroke(style: StrokeStyle(
                lineWidth: 1,
                dash: isDotted ? dottedDash : []
            ))
            .frame(height: 1)
            .foregroundColor(color)
    }

    private struct LineShape: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

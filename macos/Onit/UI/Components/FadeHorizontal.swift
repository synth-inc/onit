//
//  FadeHorizontal.swift
//  Onit
//
//  Created by Loyd Kim on 5/19/25.
//

import SwiftUI

struct FadeHorizontal: View {
    private let color: Color
    private let width: CGFloat
    private let height: CGFloat
    private let toRight: Bool
    
    init(
        color: Color,
        width: CGFloat = 24,
        height: CGFloat = 24,
        toRight: Bool = false
    ) {
        self.color = color
        self.width = width
        self.height = height
        self.toRight = toRight
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(
                        colors: [.clear, color]
                    ),
                    startPoint: toRight ? .trailing : .leading,
                    endPoint: toRight ? .leading : .trailing
                )
            )
            .frame(width: width, height: height)
    }
}

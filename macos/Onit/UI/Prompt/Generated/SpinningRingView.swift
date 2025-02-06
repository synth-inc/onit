//
//  SpinningRingView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import SwiftUI

struct SpinningRingView: View {
    @State private var rotation: Double = 270
    var size: CGFloat

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Circle()
                .stroke(lineWidth: size/3)
                .foregroundColor(.clear.opacity(0.3))
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0.0, to: 0.75)
                .stroke(style: StrokeStyle(lineWidth: size/3, lineCap: .round))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: rotation)
                .onAppear {
                    rotation = 360
                }
        }
        .frame(width: size + size/3, height: size + size/3)
    }
}

#Preview {
    SpinningRingView(size: 12)
}

//
//  WaveformIndicator.swift
//  Onit
//
//  Created by OpenHands on 3/17/2025.
//

import SwiftUI

struct WaveformIndicator: View {
    var audioLevel: Float
    
    @State private var phase = 0.0
    private let numberOfBars = 4
    private let animationDuration = 0.6
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 16
    
    init(audioLevel: Float = 0.0) {
        self.audioLevel = audioLevel
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                bar(for: index)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
    
    private func bar(for index: Int) -> some View {
        let delay = Double(index) / Double(numberOfBars) * animationDuration
        
        return Rectangle()
            .fill(Color.blue400)
            .frame(width: 2, height: barHeight(for: index))
            .animation(
                .easeInOut(duration: 0.1), // Quick response to audio changes
                value: audioLevel
            )
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        // Base height is determined by the audio level
        let baseHeight = minHeight + (maxHeight - minHeight) * CGFloat(audioLevel)
        
        // Add some variation between bars to make it look more natural
        let normalizedIndex = Double(index) / Double(numberOfBars - 1)
        let variation = sin(phase * 2 * .pi + normalizedIndex * 2 * .pi) * 0.2 + 0.8 // 0.8 to 1.2 range
        
        // If audio level is very low, still show minimal animation
        if audioLevel < 0.05 {
            let idleHeight = minHeight + 2
            let idleVariation = sin(phase * 2 * .pi + normalizedIndex * 2 * .pi) * 0.5 + 1.0
            return idleHeight * CGFloat(idleVariation)
        }
        
        return baseHeight * CGFloat(variation)
    }
}

struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue400, lineWidth: 2)
            .frame(width: 12, height: 12)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        WaveformIndicator()
        LoadingIndicator()
    }
    .padding()
    .background(Color.black)
}
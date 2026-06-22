//
//  AudioVisualizer.swift
//  Onit
//
//  Created by Loyd Kim on 1/27/26.
//

import SwiftUI

// MARK: - Audio Visualizer (Bars to Circular Loader)

/// Animated audio visualization that transforms from bars to circular loader
struct AudioVisualizer: View {
    let audioLevel: Float
    let isProcessing: Bool

    private let barCount: Int = 8
    private let barWidth: CGFloat = 3
    private let barMaxHeight: CGFloat = 16
    private let circleRadius: CGFloat = 9

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { index in
                AudioVisualizerBar(
                    index: index,
                    barCount: barCount,
                    audioLevel: audioLevel,
                    isProcessing: isProcessing,
                    barWidth: barWidth,
                    barMaxHeight: barMaxHeight,
                    circleRadius: circleRadius
                )
            }
        }
        .frame(width: isProcessing ? circleRadius * 2 + barMaxHeight : totalBarsWidth, height: barMaxHeight + 4)
        .rotationEffect(Angle(degrees: rotation))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isProcessing)
        .onChange(of: isProcessing) { _, newValue in
            if newValue {
                startRotation()
            } else {
                rotation = 0
            }
        }
    }

    private var totalBarsWidth: CGFloat {
        CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * 2
    }

    private func startRotation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

/// Individual bar that can animate between linear and circular positions
struct AudioVisualizerBar: View {
    let index: Int
    let barCount: Int
    let audioLevel: Float
    let isProcessing: Bool
    let barWidth: CGFloat
    let barMaxHeight: CGFloat
    let circleRadius: CGFloat

    private var barHeight: CGFloat {
        if isProcessing {
            // Fixed height when in circular mode
            return barMaxHeight * 0.5
        }

        // Wave pattern for audio visualization
        let normalizedIndex = CGFloat(index) / CGFloat(barCount - 1)
        let centerDistance = abs(normalizedIndex - 0.5) * 2
        let centerBoost = 1.0 - (centerDistance * 0.4)

        let minHeight: CGFloat = 3
        let level = CGFloat(audioLevel)

        let phase = Double(index) * 0.8
        let wave = sin(phase + Double(audioLevel) * 15) * 0.3 + 0.7

        let height = minHeight + (barMaxHeight - minHeight) * level * centerBoost * wave
        return max(minHeight, height)
    }

    private var xOffset: CGFloat {
        if isProcessing {
            // Position on circle
            let angle = (CGFloat(index) / CGFloat(barCount)) * 2 * .pi - .pi / 2
            return cos(angle) * circleRadius
        } else {
            // Linear position
            let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * 2
            let startX = -totalWidth / 2 + barWidth / 2
            return startX + CGFloat(index) * (barWidth + 2)
        }
    }

    private var yOffset: CGFloat {
        if isProcessing {
            // Position on circle
            let angle = (CGFloat(index) / CGFloat(barCount)) * 2 * .pi - .pi / 2
            return sin(angle) * circleRadius
        } else {
            return 0
        }
    }

    private var barRotation: Double {
        if isProcessing {
            // Rotate to point outward from circle center
            let angle = (Double(index) / Double(barCount)) * 360
            return angle
        } else {
            return 0
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: barWidth / 2)
            .fill(Color.S_0)
            .frame(width: barWidth, height: barHeight)
            .rotationEffect(Angle(degrees: barRotation))
            .offset(x: xOffset, y: yOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isProcessing)
            .animation(.linear(duration: 0.05), value: audioLevel)
    }
}

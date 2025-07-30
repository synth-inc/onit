//
//  LoaderPulse.swift
//  Onit
//
//  Created by Loyd Kim on 5/22/25.
//

import SwiftUI

struct LoaderPulse: View {
    private let size: CGFloat
    private let color: Color
    private let duration: Double
    private let pauseDuration: Double
    
    @State private var animating = false
    @State private var timer: Timer? = nil
    
    init(
        size: CGFloat = 12,
        color: Color = Color.S_1,
        duration: Double = 0.6,
        pauseDuration: Double = 0.5
    ) {
        self.size = size
        self.color = color
        self.duration = duration
        self.pauseDuration = pauseDuration
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(animating ? 1.4 : 0.5)
            .opacity(animating ? 0 : 0.8)
            .animation(
                animating ? .easeOut(duration: duration) : nil,
                value: animating
            )
            .onAppear { animatePulse() }
            .onDisappear { timer?.invalidate() }
    }
    
    private func animatePulse() {
        withAnimation(.easeOut(duration: duration)) {
            animating = true
        }
        
        // Creates delays in between pulses.
        timer = Timer.scheduledTimer(
            withTimeInterval: duration + pauseDuration,
            repeats: true
        ) { _ in
            Task { @MainActor in
                withAnimation(nil) { animating = false }
                
                try? await Task.sleep(for: .milliseconds(8))
                
                withAnimation(.easeOut(duration: duration)) {
                    animating = true
                }
            }
        }
    }
}

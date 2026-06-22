//
//  DotsWaveLoader.swift
//  Onit
//
//  Created by Kévin Naudin on 09/30/2025.
//

import SwiftUI

struct DotsWaveLoader: View {
    @State private var animate = false
    
    var size: CGFloat
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray200)
                    .frame(width: size, height: size)
                    .scaleEffect(animate ? 0.6 : 1.0)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

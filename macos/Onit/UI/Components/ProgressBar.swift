//
//  ProgressBar.swift
//  Onit
//
//  Created by Loyd Kim on 4/4/25.
//

import SwiftUI

struct ProgressBar: View {
    struct Manual {
        var progressPercentage: Double
    }
    
    struct Timed {
        var duration: TimeInterval
        var isDecreasing: Bool = false
    }
    
    var manual: Manual? = nil
    var timed: Timed? = nil
    var height: CGFloat = 4
    
    var body: some View {
        ZStack {
            if let manual = manual {
                ManualProgressBar(
                    progressPercentage: manual.progressPercentage
                )
            } else if let timed = timed {
                TimedProgressBar(
                    duration: timed.duration,
                    isDecreasing: timed.isDecreasing
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(.gray400)
        .cornerRadius(999)
    }
}

/// Child Components

struct ManualProgressBar: View {
    var progressPercentage: Double
    
    var body: some View {
        GeometryReader { geometry in
            HStack {}
                .frame(maxHeight: .infinity)
                .frame(width: geometry.size.width * progressPercentage)
                .background(.white)
        }
    }
}

struct TimedProgressBar: View {
    var duration: TimeInterval
    var isDecreasing: Bool
    
    @State private var progress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            HStack {}
                .frame(maxHeight: .infinity)
                .frame(width: geometry.size.width * (
                    isDecreasing ? 1 - progress : progress)
                )
                .background(.white)
        }
        .onAppear {
            withAnimation(.linear(duration: duration)) {
                progress = 1.0
            }
        }
    }
}


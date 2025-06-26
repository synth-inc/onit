//
//  AnimationStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct AnimationStyle {
    static let animationDuration: Double = 0.15
}

extension View {
    func addAnimation<Dependency: Equatable>(
        dependency: Dependency,
        duration: Double = AnimationStyle.animationDuration
    ) -> some View {
        self.animation(
            .easeIn(duration: duration),
            value: dependency
        )
    }
}

//
//  OnboardingAuthButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import SwiftUI

struct OnboardingAuthButton: View {
    private let icon: ImageResource
    private let action: () -> Void
    
    init(
        icon: ImageResource,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        Image(icon)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isHovered ? .gray800 : .gray900)
            .addBorder(cornerRadius: 9, stroke: .gray700)
            .scaleEffect(isPressed ? 0.98 : 1)
            .opacity(isPressed ? 0.7 : 1)
            .addAnimation(dependency: isHovered)
            .onHover{ isHovering in isHovered = isHovering }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {_ in isPressed = true }
                    .onEnded{ _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

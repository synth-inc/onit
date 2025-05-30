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
            .foregroundColor(Color.primary)
            .addBorder(cornerRadius: 9, stroke: .gray700)
            .addButtonEffects(
                background: isHovered ? .gray800 : .gray900,
                isHovered: $isHovered,
                isPressed: $isPressed,
                action: action
            )
    }
}

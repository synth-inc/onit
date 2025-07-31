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
            .foregroundColor(Color.S_0)
            .addBorder(cornerRadius: 9, stroke: Color.genericBorder)
            .addButtonEffects(
                background: isHovered ? Color.T_8 : Color.T_9,
                isHovered: $isHovered,
                isPressed: $isPressed,
                action: action
            )
    }
}

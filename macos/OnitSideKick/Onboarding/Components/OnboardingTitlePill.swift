//
//  OnboardingTitlePill.swift
//  Onit
//
//  Created by Loyd Kim on 1/20/26.
//

import SwiftUI

struct OnboardingTitlePill: View {
    // MARK: - Types
    
    struct TextConfig {
        let text: String
        var size: CGFloat = 14
    }
    
    struct IconConfig {
        let systemName: String
        var size: CGFloat = 12
    }
    
    struct ColorConfig {
        var backgroundColor: Color = Color.clear
        var border: Color = Color.T_3
    }
    
    struct StatusConfig {
        var isDotted: Bool = true
    }
    
    // MARK: - Properties
    
    private let textConfig: TextConfig
    private let leftIconConfig: IconConfig?
    private let rightIconConfig: IconConfig?
    private let colorConfig: ColorConfig
    private let statusConfig: StatusConfig
    private let action: (() -> Void)?
    
    // MARK: - Initializer
    
    init(
        textConfig: TextConfig,
        leftIconConfig: IconConfig? = nil,
        rightIconConfig: IconConfig? = nil,
        colorConfig: ColorConfig = .init(),
        statusConfig: StatusConfig = .init(),
        action: (() -> Void)? = nil
    ) {
        self.textConfig = textConfig
        self.leftIconConfig = leftIconConfig
        self.rightIconConfig = rightIconConfig
        self.colorConfig = colorConfig
        self.statusConfig = statusConfig
        self.action = action
    }
    
    // MARK: - States
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    // MARK: - Private Variables
    
    private var shouldFreeze: Bool {
        return action == nil
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            if let leftIconConfig {
                Image(systemName: leftIconConfig.systemName)
                    .font(.system(size: leftIconConfig.size))
                    .foregroundColor(Color.S_0)
            }

            Text(textConfig.text)
                .styleText(
                    size: textConfig.size,
                    weight: .regular,
                    color: Color.S_0
                )
            
            if let rightIconConfig {
                Image(systemName: rightIconConfig.systemName)
                    .font(.system(size: rightIconConfig.size))
                    .foregroundColor(Color.S_0)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .addBorder(
            cornerRadius: 999,
            stroke: colorConfig.border,
            dotted: statusConfig.isDotted
        )
        .addButtonEffects(
            background: colorConfig.backgroundColor,
            hoverBackground: colorConfig.backgroundColor.opacity(0.7),
            cornerRadius: 999,
            isHovered: $isHovered,
            isPressed: $isPressed
        ) {
            action?()
        }
        .disabled(shouldFreeze)
        .allowsHitTesting(!shouldFreeze)
    }
}

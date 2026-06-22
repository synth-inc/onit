//
//  PromptCoreFooterButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/18/25.
//

import SwiftUI

struct PromptCoreFooterButton: View {
    private let iconColor: Color
    private let icon: ImageResource
    private let text: String
    private let disabled: Bool
    private let action: () -> Void
    
    private let fontColor: Color
    private let background: Color
    private let hoverBackground: Color
    
    init(
        iconColor: Color,
        icon: ImageResource,
        text: String,
        disabled: Bool = false,
        action: @escaping () -> Void,
        
        background: Color = Color.clear,
        hoverBackground: Color = Color.T_8,
        fontColor: Color = Color.S_2
    ) {
        self.iconColor = iconColor
        self.icon = icon
        self.text = text
        self.disabled = disabled
        self.action = action
        
        self.background = background
        self.hoverBackground = hoverBackground
        self.fontColor = fontColor
    }
    
    var body: some View {
        TextButton(
            text: text,
            iconConfig: .init(
                leftIconImage: icon
            ),
            colorConfig: .init(
                text: fontColor,
                background: background,
                hoverBackground: hoverBackground
            ),
            sizeConfig: .init(
                text: 13,
                horizontalPadding: 4,
                height: ToolbarButtonStyle.height,
                cornerRadius: 4
            ),
            alignmentConfig: .init(
                gap: 4
            ),
            statusConfig: .init(
                disabled: disabled
            ),
            action: action
        )
    }
}

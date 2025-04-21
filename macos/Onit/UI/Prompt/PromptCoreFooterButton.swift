//
//  PromptCoreFooterButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/18/25.
//

import SwiftUI

struct PromptCoreFooterButton: View {
    private let text: String
    private let disabled: Bool
    private let action: () -> Void
    
    private let fontColor: Color
    private let background: Color
    private let hoverBackground: Color
    
    init(
        text: String,
        disabled: Bool = false,
        action: @escaping () -> Void,
        
        background: Color = .clear,
        hoverBackground: Color = .gray600,
        fontColor: Color = .gray200
    ) {
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
            disabled: disabled,
            action: action,
            height: toolbarButtonHeight,
            fillContainer: false,
            horizontalPadding: 4,
            cornerRadius: 4,
            background: background,
            hoverBackground: hoverBackground,
            fontSize: 12,
            fontWeight: .semibold,
            fontColor: fontColor
        )
    }
}

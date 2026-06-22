//
//  SettingsSelectionButton.swift
//  Onit
//
//  Created by Loyd Kim on 11/26/25.
//

import SwiftUI

struct SettingsSelectionButton: View {
    // MARK: - Properties
    
    private let text: String
    private let selected: Bool
    private let action: () -> Void
    
    // MARK: - Initializer
    
    init(
        text: String,
        selected: Bool,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.selected = selected
        self.action = action
    }
    
    // MARK: - States
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center) {
            Text(self.text)
                .styleText(
                    size: 13,
                    weight: .regular
                )
            
            Spacer()
            
            if self.selected {
                Image(systemName: "checkmark")
                    .styleText(
                        size: 12,
                        weight: .semibold,
                        color: Color.accentColor
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .addButtonEffects(
            background: self.selected ? Color.accentColor.opacity(0.1) : Color.clear,
            hoverBackground: self.selected ? Color.accentColor.opacity(0.1) : Color.S_0.opacity(0.05),
            cornerRadius: 4,
            isHovered: self.$isHovered,
            isPressed: self.$isPressed
        ) {
            self.action()
        }
    }
}

//
//  SetUpButton.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

enum SetUpButtonVariant {
    case primary
    case `default`
}

struct SetUpButtonStyle: ButtonStyle {
    var showArrow: Bool
    var variant: SetUpButtonVariant = .default

    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.label
            if showArrow {
                Text("→")
                    .offset(x: hovering ? 2 : 0)
            }
        }

        .padding(8)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor.opacity(hovering ? 0.9 : 1), in: .rect(cornerRadius: 6))
        .opacity(configuration.isPressed ? 0.9 : 1)
        .animation(.spring(duration: 1 / 3), value: hovering)
        .fontWeight(.semibold)
        .onContinuousHover { phase in
            if case .active = phase {
                hovering = true
            } else {
                hovering = false
            }
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return Color.S_0
        case .default:
            return Color.S_0
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Color.blue400
        case .default:
            return Color.T_8
        }
    }
}

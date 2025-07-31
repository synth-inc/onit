//
//  MenuButtonStyle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuButtonStyle: ButtonStyle {
    @State private var hovering = false

    var style: AnyShapeStyle {
        hovering ? AnyShapeStyle(Color.T_8) : AnyShapeStyle(Color.clear)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(style)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    hovering = true
                case .ended:
                    hovering = false
                }
            }
    }
}

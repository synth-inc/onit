//
//  ToastPanelView.swift
//  Onit
//
//  Created by Loyd Kim on 5/21/26.
//

import SwiftUI

struct ToastPanelView: View {
    // MARK: - Types

    struct SizeConfigs {
        var width: CGFloat? = nil
        var height: CGFloat? = nil
    }

    // MARK: - Properties

    let message: String
    var sizeConfigs: SizeConfigs = .init()
    let dismissAction: () -> Void

    // MARK: - States

    @State private var hoveredToast: Bool = false
    @State private var pressedToast: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .styleText(
                    color: Color.lime500
                )

            Text(message)
                .styleText(
                    weight: .regular,
                    color: Color.S_10
                )
                /// Allows the capsule to grow to fit its message, rather than compressing the message to fit the capsule.
                /// Without this, a message wider than the parent panel's measured size renders with a tail ellipsis (e.g. "Marked as unreview...")
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(12)
        .frame(width: sizeConfigs.width, alignment: .center)
        .frame(height: sizeConfigs.height, alignment: .center)
        .addButtonEffects(
            background: Color.S_0,
            hoverBackground: Color.S_0.opacity(0.7),
            cornerRadius: 999,
            isHovered: $hoveredToast,
            isPressed: $pressedToast
        ) {
            dismissAction()
        }
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 2)
        .padding(8) /// Just enough room for the shadow to render without clipping; any larger creates a transparent click area that swallows clicks intended for content around it.
    }
}

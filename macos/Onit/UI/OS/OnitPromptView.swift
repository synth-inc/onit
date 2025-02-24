//
//  OnitPromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import KeyboardShortcuts
import SwiftUI

struct OnitPromptView: View {
    @Environment(\.model) var model
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    var shortcut: KeyboardShortcut? {
        KeyboardShortcuts.getShortcut(for: .launch)?.native
    }

    var body: some View {
        if model.panel == nil {
            HStack(spacing: 3) {
                Image(.smirk)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                    .font(.system(size: 13, weight: .light))
            }
            .foregroundStyle(Color.secondary)
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.thickMaterial)
            }
            .padding(.vertical, 5)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        offset = value.translation
                    }
                    .onEnded { value in
                        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                        if distance > 50 {
                            let screenSize = NSScreen.main?.frame.size ?? .zero
                            let angle = atan2(value.translation.height, value.translation.width)
                            let finalX = cos(angle) * screenSize.width * 2
                            let finalY = sin(angle) * screenSize.height * 2

                            withAnimation(.easeOut) {
                                offset = CGSize(width: finalX, height: finalY)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                model.dismissPanel()
                            }
                        } else {
                            withAnimation(.easeOut) {
                                offset = .zero
                                isDragging = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if !isDragging {
                    model.launchPanel()
                }
            }
        }
    }
}

#Preview {
    OnitPromptView()
}

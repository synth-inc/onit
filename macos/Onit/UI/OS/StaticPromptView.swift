//
//  StaticPromptView.swift
//  Onit
//
//  Created by Timothy Lenardo on 11/9/24.
//

import KeyboardShortcuts
import SwiftUI

struct StaticPromptView: View {
    @Environment(\.model) var model
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    var shortcut: KeyboardShortcut? {
        KeyboardShortcuts.getShortcut(for: .launch)?.native
    }

    var body: some View {
        if model.panel == nil {
            // Reset offset when view appears
            let _ = DispatchQueue.main.async {
                offset = 0
                isDragging = false
            }
            VStack(spacing: 3) {
                Image(.smirk)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(5)
                KeyboardShortcutView(shortcut: shortcut, characterWidth: 13, spacing: 3)
                    .font(.system(size: 13, weight: .light))
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.bottom, 4)
                    .padding(.top, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.gray400, lineWidth: 1)
                    )
            }
            .foregroundStyle(Color.white)
            .padding(10)
            .background(Color.black)
            .clipShape(
                .rect(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width > 0 {
                            isDragging = true
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width > 50 {
                            withAnimation(.easeOut) {
                                offset = NSScreen.main?.frame.width ?? 1000
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                model.dismissPanel()
                            }
                        } else {
                            withAnimation(.easeOut) {
                                offset = 0
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
    StaticPromptView()
}

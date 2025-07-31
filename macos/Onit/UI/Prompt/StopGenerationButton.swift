//
//  StopGenerationButton.swift
//  Onit
//
//  Created by OpenAI on 2023-11-20.
//

import SwiftUI
import Defaults

struct StopGenerationButton: View {
    @Environment(\.windowState) private var state
    @State private var isHovered: Bool = false

    private let shortcut = KeyboardShortcut(.delete, modifiers: [.command])

    var body: some View {
        // Only show content if windowState is available
        if let state = state {
            Button(action: { state.stopGeneration() }) {
                HStack(spacing: 4) {
                    Image(systemName: "command")
                        .font(.system(size: 10))
                        .foregroundColor(Color.S_0)
                    
                    Image(systemName: "delete.left")
                        .font(.system(size: 10))
                        .foregroundColor(Color.S_0)
                    
                    Text("Stop")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.S_0)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 0)
                .frame(height: 26)
            }
            .buttonStyle(PlainButtonStyle())
            .background(isHovered ? Color.T_8 : Color.elevatedBG)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovered ? Color.T_5 : Color.genericBorder, lineWidth: 1)
            )
            .keyboardShortcut(shortcut)
            .onHover { hovering in
                isHovered = hovering
            }
            .addAnimation(dependency: isHovered)
        } else {
            EmptyView()
        }
    }
}

//
//  QuickEditHintView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import SwiftUI

struct QuickEditHintView: View {
    @State private var isHovered: Bool = false
    @EnvironmentObject private var windowController: QuickEditHintWindowController
    
    private let hintSize: CGFloat = 12
    private let hoverScale: CGFloat = 1.2
    
    private var shouldShowDotsIcon: Bool {
        let allowedApps = ["Notes", "Pages", "Slack"]
        return allowedApps.contains(windowController.currentAppName)
    }
    
    // MARK: - Custom Menu Methods
    
    private func showMenu() {
        let mouseLocation = NSEvent.mouseLocation
        windowController.showMenu(at: mouseLocation)
    }
    
    var body: some View {
        HStack {
            Button(
                action: { QuickEditManager.shared.show() },
                label: {
                    if shouldShowDotsIcon || isHovered {
                        Image(.dots)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: hintSize, height: hintSize)
                    } else {
                        Color.clear
                            .frame(width: 4, height: hintSize)
                    }
            })
            .tooltip(prompt: "⌘ K", background: false)
            .padding(.vertical, 8)
            .padding(.horizontal, 1)
        }
        .background(.blue300)
        .addBorder(cornerRadius: 8, inset: 0, stroke: .blue400)
        .transition(.scale.combined(with: .opacity))
        .scaleEffect(isHovered ? hoverScale : 1.0)
        .opacity(isHovered ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .rightClickable {
            showMenu()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    QuickEditHintView()
        .background(Color.gray.opacity(0.2))
} 

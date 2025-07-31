//
//  QuickEditHintView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import SwiftUI
import KeyboardShortcuts

struct QuickEditHintView: View {
    @State private var isHovered: Bool = false
    @ObservedObject private var quickEditManager = QuickEditManager.shared
    
    static let hintWidth: CGFloat = 12
    static let hoverScale: CGFloat = 1.2
    static let horizontalPadding: CGFloat = 1
    static let verticalPadding: CGFloat = 8
    
    private let height: CGFloat?
    
    init(height: CGFloat? = nil) {
        self.height = height
    }
    
    private var shouldShowDotsIcon: Bool {
        let allowedApps = ["Notes", "Pages", "Slack"]
        
        return allowedApps.contains(quickEditManager.currentAppName ?? "") || isHovered
    }
    
    var body: some View {
        HStack {
            Button(
                action: { QuickEditManager.shared.show() },
                label: {
                    if shouldShowDotsIcon {
                        Image(.dots)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Self.hintWidth, height: Self.hintWidth)
                    } else {
                        Color.clear
                            .frame(width: 4, height: Self.hintWidth)
                    }
                }
            )
            .tooltip(prompt: KeyboardShortcuts.Name.quickEdit.shortcutText, background: false)
            .padding(.vertical, Self.verticalPadding)
            .padding(.horizontal, Self.horizontalPadding)
        }
        .frame(height: height)
        .background(Color.blue300)
        .addBorder(cornerRadius: 8, inset: 0, stroke: Color.blue400)
        .onHover { hovering in
            isHovered = hovering
        }
        .transition(.scale.combined(with: .opacity))
        .scaleEffect(isHovered ? Self.hoverScale : 1.0)
        .opacity(isHovered ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

#Preview {
    QuickEditHintView()
        .background(Color.gray.opacity(0.2))
} 

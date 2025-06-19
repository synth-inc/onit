//
//  QuickEditHintMenuView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/19/2025.
//

import SwiftUI

struct QuickEditHintMenuView: View {
    @EnvironmentObject private var windowController: QuickEditHintWindowController
    @State private var hoveredItem: Int? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Onit Quick Edit")
                    .font(.system(size: 13))
                    .foregroundColor(.gray100)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            VStack(spacing: 4) {
                menuItem(
                    index: 0,
                    icon: Image(.circleX),
                    title: "Turn Off in \(windowController.currentAppName)",
                    action: turnOffAction
                )
                
                menuItem(
                    index: 1,
                    icon: Image(.clockSnooze),
                    title: "Hide in \(windowController.currentAppName) for 1h",
                    action: hideAction
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray900)
                .stroke(.gray500, lineWidth: 1)
        )
        .frame(width: 240, height: 120)
    }
    
    @ViewBuilder
    private func menuItem(
        index: Int,
        icon: Image,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            windowController.hideMenu()
        }) {
            HStack(spacing: 12) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hoveredItem == index ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            hoveredItem = isHovered ? index : nil
        }
    }
    
    // MARK: - Actions
    
    private func turnOffAction() {
        print("Turn off in \(windowController.currentAppName)")
        // TODO: KNA - Implement the feature
    }
    
    private func hideAction() {
        print("Hide in \(windowController.currentAppName) for 1h")
        // TODO: KNA - Implement the feature
    }
}

#Preview {
    QuickEditHintMenuView()
        .environmentObject({
            let controller = QuickEditHintWindowController()
            controller.currentAppName = "Notes"
            return controller
        }())
} 

//
//  QuickEditHintMenuView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/19/2025.
//

import SwiftUI
import Defaults

struct QuickEditHintMenuView: View {
    @ObservedObject private var quickEditManager = QuickEditManager.shared
    @State private var hoveredItem: Int? = nil
	@Default(.quickEditConfig) private var config
    
    private var currentAppName: String {
        quickEditManager.currentAppName ?? "Unknown"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Onit Quick Edit")
                    .font(.system(size: 13))
                    .foregroundColor(Color.S_1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            VStack(spacing: 4) {
                menuItem(
                    index: 0,
                    icon: Image(.circleX),
                    title: "Turn Off in \(currentAppName)",
                    action: turnOffAction
                )
                
                menuItem(
                    index: 1,
                    icon: Image(.clockSnooze),
                    title: "Hide in \(currentAppName) for 1h",
                    action: hideAction
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.S_9)
                .stroke(Color.S_5, lineWidth: 1)
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
            quickEditManager.hideMenu()
        }) {
            HStack(spacing: 12) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.S_0)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Color.S_0)
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
        guard let appName = quickEditManager.currentAppName else { return }
        
        config.excludedApps.insert(appName)
        
        QuickEditManager.shared.hideHint()
    }
    
    private func hideAction() {
        guard let appName = quickEditManager.currentAppName else { return }
        
        config.pausedApps[appName] = Date().addingTimeInterval(3600)
        
        QuickEditManager.shared.hideHint()
    }
}

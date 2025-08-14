//
//  ContextMenuWindowButton.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuWindowButton: View {
    @Environment(\.windowState) private var windowState
    
    private let isLoadingIntoContext: Bool
    private let selected: Bool
    private let trackedWindow: TrackedWindow
    private let windowContextItem: Context?
    private let action: () -> Void
    
    init(
        isLoadingIntoContext: Bool,
        selected: Bool,
        trackedWindow: TrackedWindow,
        windowContextItem: Context?,
        action: @escaping () -> Void
    ) {
        self.isLoadingIntoContext = isLoadingIntoContext
        self.selected = selected
        self.trackedWindow = trackedWindow
        self.windowContextItem = windowContextItem
        self.action = action
    }
    
    private var windowName: String {
        WindowHelpers.getWindowName(window: trackedWindow.element)
    }
    
    private var windowIcon: NSImage? {
        WindowHelpers.getWindowIcon(window: trackedWindow.element)
    }
    
    var body: some View {
        TextButton(
            background: selected ? Color.T_8 : Color.clear,
            icon: windowIcon == nil ? .stars : nil,
            iconImage: windowIcon,
            text: windowName
        ){
            if isLoadingIntoContext {
                LoaderPulse()
            } else if windowContextItem == nil {
                checkEmpty
            } else {
                checkFilled
            }
        } action: {
            action()
        }
        .addAnimation(dependency: selected)
    }
}

// MARK: - Child Components

extension ContextMenuWindowButton {
    private var checkEmpty: some View {
        Circle()
            .frame(width: 14, height: 14)
            .background(Color.T_8).opacity(0.2)
            .addBorder(
                cornerRadius: 999,
                stroke: Color.T_7
            )
    }
    
    private var checkFilled: some View {
        Image(.check)
            .addIconStyles(foregroundColor: Color.white, iconSize: 8)
            .frame(width: 14, height: 14)
            .background(Color.blue400)
            .addBorder(
                cornerRadius: 999,
                stroke: Color.blue300
            )
    }
}

//
//  ContextMenuWindowButton.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuWindowButton: View {
    private let isLoadingIntoContext: Bool
    private let selected: Bool
    private let windowName: String
    private let windowContextItem: Context?
    private let windowIcon: NSImage?
    private let action: () -> Void
    
    init(
        isLoadingIntoContext: Bool,
        selected: Bool,
        windowName: String,
        windowContextItem: Context?,
        windowIcon: NSImage? = nil,
        action: @escaping () -> Void
    ) {
        self.isLoadingIntoContext = isLoadingIntoContext
        self.selected = selected
        self.windowName = windowName
        self.windowContextItem = windowContextItem
        self.windowIcon = windowIcon
        self.action = action
    }
    
    var body: some View {
        TextButton(
            background: selected ? .gray600 : .clear,
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
    }
}

// MARK: - Child Components

extension ContextMenuWindowButton {
    private var checkEmpty: some View {
        Circle()
            .frame(width: 14, height: 14)
            .background(.T_8).opacity(0.2)
            .addBorder(
                cornerRadius: 999,
                stroke: .T_7
            )
    }
    
    private var checkFilled: some View {
        Image(.check)
            .addIconStyles(iconSize: 8)
            .frame(width: 14, height: 14)
            .background(.blue400)
            .addBorder(
                cornerRadius: 999,
                stroke: .blue300
            )
    }
}

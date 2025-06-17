//
//  ContextPickerItemView.swift
//  Onit
//
//  Created by Kévin Naudin on 28/01/2025.
//

import SwiftUI

struct ContextPickerItemView: View {
    @Environment(\.windowState) private var windowState
    
    private let showEmptyIcon: Bool
    private let imageRes: ImageResource
    private let title: String
    private let subtitle: String
    private let action: () -> Void
    
    init(
        showEmptyIcon: Bool = false,
        imageRes: ImageResource,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.showEmptyIcon = showEmptyIcon
        self.imageRes = imageRes
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    private var windowIcon: NSImage? {
        guard let foregroundWindow = windowState.foregroundWindow,
              let bundleUrl = windowState.getWindowAppBundleUrl(window: foregroundWindow.element)
        else {
            return nil
        }
        
        return NSWorkspace.shared.icon(forFile: bundleUrl.path)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if showEmptyIcon {
                Rectangle()
                    .fill(.T_8)
                    .frame(width: 20, height: 20)
                    .cornerRadius(4.5)
            } else if let windowIcon = windowIcon {
                Image(nsImage: windowIcon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .cornerRadius(4.5)
            } else {
                Image(imageRes)
                    .resizable()
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .styleText(size: 14, weight: .regular, color: .white)
                
                Text(subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .styleText(size: 13, weight: .regular, color: .gray200)
                    .truncateText()
            }
        }
        .frame(width: 210)
        .padding(6)
        .addButtonEffects(
            background: .gray600,
            hoverBackground: .gray500,
            cornerRadius: 8,
            isHovered: $isHovered,
            isPressed: $isPressed,
            action: action
        )
    }
}

#Preview {
    ContextPickerItemView(
        imageRes: .arrowsSpin,
        title: "",
        subtitle: "",
        action: { print("Preview") }
    )
}

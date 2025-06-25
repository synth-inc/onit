//
//  SettingsSection.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import SwiftUI

struct SettingsSection<Child: View>: View {
    private let iconText: String?
    private let iconSystem: String?
    private let iconImage: ImageResource?
    private let iconSize: CGFloat
    private let title: String
    private let spacing: CGFloat
    @ViewBuilder private let child: () -> Child
    
    init(
        iconText: String? = nil,
        iconSystem: String? = nil,
        iconImage: ImageResource? = nil,
        iconSize: CGFloat = 14,
        title: String,
        spacing: CGFloat = 8,
        @ViewBuilder child: @escaping () -> Child
    ) {
        self.iconText = iconText
        self.iconSystem = iconSystem
        self.iconImage = iconImage
        self.iconSize = iconSize
        self.title = title
        self.spacing = spacing
        self.child = child
    }
    
    var body: some View {
        Section(header: header) {
            child()
        }
        .padding(3)
    }
}

// MARK: - Child Components

extension SettingsSection {
    private var header: some View {
        HStack(alignment: .center, spacing: spacing) {
            if let iconText = iconText {
                Text(iconText)
                    .styleText(weight: .regular)
            } else if let iconSystem = iconSystem {
                Image(systemName: iconSystem)
                    .addIconStyles(iconSize: iconSize)
            } else if let iconImage = iconImage {
                Image(iconImage)
                    .addIconStyles(iconSize: iconSize)
            }
            
            Text(title).styleText(weight: .regular)
        }
    }
}

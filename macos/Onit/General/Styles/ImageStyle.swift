//
//  ImageStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

extension Image {
    func addIconStyles(
        foregroundColor: Color = Color.primary,
        iconSize: CGFloat = 20
    ) -> some View {
        self
            .resizable()
            .renderingMode(.template)
            .foregroundColor(foregroundColor)
            .frame(width: iconSize, height: iconSize)
    }
}

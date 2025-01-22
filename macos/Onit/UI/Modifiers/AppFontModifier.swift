//
//  AppFontModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

private struct AppFontModifier: ViewModifier {
    let appFont: AppFont

    func body(content: Content) -> some View {
        content
            .font(appFont.font)
            .kerning(appFont.kearning)
            .lineSpacing(appFont.lineSpacing)
//            .padding(.vertical, (lineHeight - font.lineHeight) / 2)
    }
}

extension View {
    func appFont(_ appFont: AppFont) -> some View {
        modifier(AppFontModifier(appFont: appFont))
    }
}

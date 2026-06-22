//
//  ViewHeightModifier.swift
//  Onit
//
//  Created by Kévin Naudin on 14/04/2025.
//

import SwiftUI

struct ViewHeightKey: @preconcurrency PreferenceKey {
    @MainActor static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ViewHeightModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ViewHeightKey.self, value: geometry.size.height)
                }
            )
    }
}

extension View {
    func onHeightChanged(callback: @escaping ((CGFloat) -> Void)) -> some View {
        self.modifier(ViewHeightModifier())
            .onPreferenceChange(ViewHeightKey.self, perform: callback)
    }
}

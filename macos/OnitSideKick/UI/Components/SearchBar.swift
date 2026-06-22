//
//  SearchBar.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchQuery: String
    var placeholder: String = String.localized("Search for...", table: "Sidekick")
    var sidePadding: CGFloat = 0
    var config = Self.config()
    
    static func config(
        width: CGFloat? = nil,
        height: CGFloat = 32,
        background: Color = Color.clear,
        cornerRadius: CGFloat = 8,
        onClear: (() -> Void)? = nil
    ) -> CustomTextField.Config {
        return .init(
            width: width,
            height: height,
            background: background,
            cornerRadius: cornerRadius,
            clear: true,
            leftIcon: .search,
            shouldFocusOnAppear: true
        ) {
            onClear?()
        }
    }
    
    var body: some View {
        CustomTextField(
            text: $searchQuery,
            placeholder: placeholder,
            sidePadding: sidePadding,
            config: config
        )
    }
}

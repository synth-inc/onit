//
//  SearchBar.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchQuery: String
    let placeholder: String
    let sidePadding: CGFloat
    let background: Color
    
    init(
        searchQuery: Binding<String>,
        placeholder: String = "Search for...",
        sidePadding: CGFloat = 0,
        background: Color = Color.T_9
    ) {
        self._searchQuery = searchQuery
        self.placeholder = placeholder
        self.sidePadding = sidePadding
        self.background = background
    }
    
    var body: some View {
        CustomTextField(
            text: $searchQuery,
            placeholder: placeholder,
            sidePadding: sidePadding,
            config: CustomTextField.Config(
                background: background,
                clear: true,
                leftIcon: .search
            )
        )
    }
}

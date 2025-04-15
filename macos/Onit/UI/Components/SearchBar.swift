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
    
    init(
        searchQuery: Binding<String>,
        placeholder: String = "Search for...",
        sidePadding: CGFloat = 0
    ) {
        self._searchQuery = searchQuery
        self.placeholder = placeholder
        self.sidePadding = sidePadding
    }
    
    var body: some View {
        CustomTextField(
            text: $searchQuery,
            placeholder: placeholder,
            sidePadding: sidePadding,
            config: CustomTextField.Config(
                background: .gray800,
                clear: true,
                leftIcon: .search
            )
        )
    }
}

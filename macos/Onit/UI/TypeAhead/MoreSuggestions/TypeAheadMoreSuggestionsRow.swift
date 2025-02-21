//
//  TypeAheadMoreSuggestionsRow.swift
//  Onit
//
//  Created by Kévin Naudin on 21/02/2025.
//

import SwiftUI

struct TypeAheadMoreSuggestionsRow: View {
    let text: String
//    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.gray100)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(backgroundColor)
                    .opacity(isHovered/* || isSelected*/ ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
//            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isHovered /*|| isSelected */{
            return .gray800
        }
        return .clear
    }
}

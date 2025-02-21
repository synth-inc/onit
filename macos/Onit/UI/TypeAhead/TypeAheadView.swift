//
//  TypeAheadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import SwiftUI

struct TypeAheadView: View {
    private let moreSuggestionsState = TypeAheadMoreSuggestionsState.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if !moreSuggestionsState.isLoading && moreSuggestionsState.moreSuggestions.isEmpty {
                TypeAheadCompletionView()
            } else {
                TypeAheadMoreSuggestionsView()
                //Text(state.moreSuggestions.joined(separator: "\n"))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.typeAheadBG)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    TypeAheadView()
}

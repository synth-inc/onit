//
//  TypeAheadMoreSuggestionsView.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//


import SwiftUI

struct TypeAheadMoreSuggestionsView: View {
    @State private var selectedIndex: Int = 0
    
    private let globalState = TypeAheadState.shared
    private let state = TypeAheadMoreSuggestionsState.shared
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(state.moreSuggestions.indices, id: \.self) { index in
                    Text(state.moreSuggestions[index])
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray100)
                        .padding(8)
                        .background(selectedIndex == index ? Color.blue.opacity(0.3) : Color.clear)
                        .cornerRadius(5)
                }
            }
        }
        .frame(width: 200, height: 150)
        .onKeyDown { event in
            handleKeyPress(event)
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        guard !state.moreSuggestions.isEmpty else { return }
        
        switch event.keyCode {
        case 36: // Enter
            globalState.insertSuggestion(text: state.moreSuggestions[selectedIndex])
        case 126: // Up Arrow
            if selectedIndex > 0 {
                self.selectedIndex = selectedIndex - 1
            } else {
                self.selectedIndex = state.moreSuggestions.count - 1
            }
        case 125: // Down Arrow
            if selectedIndex < state.moreSuggestions.count - 1 {
                self.selectedIndex = selectedIndex + 1
            } else {
                self.selectedIndex = 0
            }
        default:
            break
        }
    }
}

#Preview {
    TypeAheadMoreSuggestionsView()
}

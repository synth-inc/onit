//
//  TypeAheadMoreSuggestionsView.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//


import SwiftUI

struct TypeAheadMoreSuggestionsView: View {
//    @State private var selectedIndex: Int = 0
    @State private var showPopover: Bool = false
    
    private let globalState = TypeAheadState.shared
    private let state = TypeAheadMoreSuggestionsState.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                if state.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                ForEach(state.moreSuggestions.indices, id: \.self) { index in
                    TypeAheadMoreSuggestionsRow(
                        text: state.moreSuggestions[index],
//                        isSelected: selectedIndex == index,
                        isHovered: state.hoveredIndex == index
                    )
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.hoveredIndex = isHovered ? index : nil
                        }
                    }
                    .popover(
                        isPresented: .init(
                            get: { state.hoveredIndex == index },
                            set: { _ in }
                        )
                    ) {
                        let text = index < state.moreSuggestions.count ? state.moreSuggestions[index] : ""
                        
                        TypeAheadMoreSuggestionsDetail(text: text)
                            .transition(.opacity)
                    }
                }
            }
        }
        .frame(maxWidth: 200, maxHeight: 150)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.typeAheadBG)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
//    private func handleKeyPress(_ event: NSEvent) {
//        guard !state.moreSuggestions.isEmpty else { return }
//        
//        switch event.keyCode {
//        case 36: // Enter
//            guard let index = hoveredIndex, index < state.moreSuggestions.count else {
//                return
//            }
//            globalState.insertSuggestion(text: state.moreSuggestions[index])
//        case 126: // Up Arrow
//            if selectedIndex > 0 {
//                self.selectedIndex = selectedIndex - 1
//            } else {
//                self.selectedIndex = state.moreSuggestions.count - 1
//            }
//        case 125: // Down Arrow
//            if selectedIndex < state.moreSuggestions.count - 1 {
//                self.selectedIndex = selectedIndex + 1
//            } else {
//                self.selectedIndex = 0
//            }
//        default:
//            break
//        }
//    }
}

#Preview {
    TypeAheadMoreSuggestionsView()
}

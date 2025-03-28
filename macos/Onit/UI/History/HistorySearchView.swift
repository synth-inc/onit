//
//  HistorySearchView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistorySearchView: View {
    @Binding var text: String
    var onSearch: (String) -> Void
    @FocusState private var isFocused: Bool

    @State private var debounceTask: Task<Void, Never>? = nil

    private var debouncedBinding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = newValue
            }
        )
    }

    var rect: some Shape {
        .rect(cornerRadius: 10)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(.search)

            ZStack(alignment: .leading) {
                TextField("", text: debouncedBinding)
                    .tint(.blue600)
                    .fixedSize(horizontal: false, vertical: true)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        // Cancel any existing task
                        debounceTask?.cancel()
                        // Create new task with delay
                        debounceTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                            guard !Task.isCancelled else { return }
                            onSearch(newValue)  // Notify parent after debounce
                        }
                    }

                if text.isEmpty {
                    placeholderView
                } else {
                    Text(" ")
                }
            }
            .appFont(.medium16)
            .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.gray900, in: rect)
        .overlay {
            rect.stroke(.gray700)
        }
        .padding(.horizontal, 10)
        .allowsHitTesting(true)
    }

    var placeholderView: some View {
        Text("Search prompts")
            .foregroundStyle(.gray300)
            .allowsHitTesting(false)
    }
}

#Preview {
    HistorySearchView(text: .constant("Hello"), onSearch: { _ in })
}

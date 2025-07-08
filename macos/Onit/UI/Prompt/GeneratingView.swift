//
//  GeneratingView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratingView: View {
    @Environment(\.windowState) private var state
    
    var prompt: Prompt

    var delete: KeyboardShortcut {
        .init(.delete, modifiers: [.command])
    }

    var body: some View {
        // Only show content if windowState is available
        if let state = state {
            HStack {
                Spacer()
                
                Button {
                    state.cancelGenerate()
                    state.textFocusTrigger.toggle()
                } label: {
                    VStack(spacing: 12) {
                        icon
                        text
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(delete)
                Spacer()
            }
        } else {
            EmptyView()
        }
    }

    var icon: some View {
        Image(.word)
            .shimmering()
    }

    var text: some View {
        HStack(spacing: 4) {
            Text("Cancel")
                .foregroundStyle(.gray200)
            KeyboardShortcutView(shortcut: delete)
                .foregroundStyle(.gray300)
        }
        .appFont(.medium13)
    }
}

#if DEBUG
    #Preview {
        //        GeneratingView()
    }
#endif

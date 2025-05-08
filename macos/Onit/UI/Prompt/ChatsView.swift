//
//  ChatsView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import Defaults
import SwiftUI

struct ChatsView: View {
    @Environment(\.windowState) private var state
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(state.currentPrompts ?? []) { prompt in
                Rectangle() // This is very odd. Without this, we get about 20px of vertical padding that I can't explain.
                    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: 0)
                    .padding(0)
                PromptView(prompt: prompt)
            }
        }
    }
}

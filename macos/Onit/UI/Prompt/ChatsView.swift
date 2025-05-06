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
    
    @Default(.isPanelExpanded) var isPanelExpanded: Bool
    @Default(.isRegularApp) var isRegularApp: Bool
    
    @State private var contentHeight: CGFloat = 0
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0

    var maxHeight: CGFloat? {
        guard !isRegularApp, screenHeight != 0 else { return nil }
        
        let availableHeight = screenHeight - state.headerHeight -
        state.inputHeight - state.setUpHeight -
        state.systemPromptHeight - ContentView.bottomPadding
        
        return availableHeight
    }
    
    var realHeight: CGFloat? {
        guard !isRegularApp, let maxHeight = maxHeight else { return nil}
        
        return isPanelExpanded ? maxHeight : min(contentHeight, maxHeight)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(state.currentPrompts ?? []) { prompt in
                Rectangle() // This is very odd. Without this, we get about 20px of vertical padding that I can't explain.
                    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: 0)
                    .padding(0)
                PromptView(prompt: prompt)
            }
        }
        .onHeightChanged {
            guard !isRegularApp else { return }
            
            let oldHeight = realHeight
            contentHeight = $0
                                
            if oldHeight != realHeight {
                state.panel?.adjustSize()
            }
        }
        .trackScreenHeight($screenHeight)
    }
    
}

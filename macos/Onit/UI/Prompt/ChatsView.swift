//
//  ChatsView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import Defaults
import SwiftUI

struct ChatsView: View {
    @Environment(\.model) var model
    
    private let currentPromptsCount: Int
    
    init(currentPromptsCount: Int) {
        self.currentPromptsCount = currentPromptsCount
    }
    
    @State private var isScrolling: Bool = false
    @State private var scrollTask: Task<Void, Never>?
    
    private func scrollToBottom(using proxy: ScrollViewProxy) {
        guard !isScrolling else { return }
        
        isScrolling = true
        scrollTask?.cancel()
        
        scrollTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeIn(duration: animationDuration)) {
                proxy.scrollTo("scrollToBottomElement", anchor: .bottom)
            }
            
            isScrolling = false
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: -16) {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        PromptView(prompt: prompt)
                    }
                }
                .opacity(currentPromptsCount > 0 ? 1 : 0)
                .addAnimation(dependency: currentPromptsCount)
                
                Color.clear
                    .frame(height: 1)
                    .id("scrollToBottomElement")
            }
            .onChange(of: currentPromptsCount) {
                if currentPromptsCount > 0 { scrollToBottom(using: proxy) }
            }
            .onChange(of: model.currentChat) { old, new in
                if old == nil && new != nil { return }
                scrollToBottom(using: proxy)
            }
        }
        .frame(
            height: currentPromptsCount > 0 ? nil : 0,
            alignment: .top
        )
    }
}

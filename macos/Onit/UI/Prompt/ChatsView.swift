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
    @Default(.isPanelExpanded) var isPanelExpanded: Bool
    @Default(.isRegularApp) var isRegularApp: Bool
    
    @State private var contentHeight: CGFloat = 0
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0
    @State private var isScrolling: Bool = false
    @State private var scrollTask: Task<Void, Never>?
    
    private var chatsID: Int? {
        model.currentChat?.hashValue
    }
    
    var maxHeight: CGFloat {
        guard !model.resizing, screenHeight != 0 else { return 0 }
        
        let availableHeight = screenHeight - model.headerHeight -
        model.inputHeight - model.setUpHeight -
        model.systemPromptHeight - ContentView.bottomPadding
        
        return availableHeight
    }
    
    var realHeight: CGFloat {
        return isRegularApp ? maxHeight : (isPanelExpanded ? maxHeight : min(contentHeight, maxHeight))
    }
    
    private func scrollToBottom(using proxy: ScrollViewProxy) {
        guard !isScrolling else { return }
        
        isScrolling = true
        scrollTask?.cancel()
        
        scrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.smooth(duration: 0.1)) {
                proxy.scrollTo(chatsID, anchor: .bottom)
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
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
                .id(chatsID)
                .background(heightReader(scrollProxy: proxy))
            }
            .screenHeight(binding: $screenHeight)
            .frame(
                minHeight: 0,
                idealHeight: realHeight,
                maxHeight: maxHeight,
                alignment: .top
            )
            .onChange(of: model.currentPrompts?.count) { _, _ in
                scrollToBottom(using: proxy)
            }
            .onChange(of: model.currentChat) { old, new in
                if old == nil && new != nil {
                    return
                }
                scrollToBottom(using: proxy)
            }
        }
    }
    
    func heightReader(scrollProxy: ScrollViewProxy) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    let oldHeight = realHeight
                    contentHeight = proxy.size.height
                    
                    if oldHeight != realHeight {
                        model.adjustPanelSize()
                    } else {
                        scrollToBottom(using: scrollProxy)
                    }
                }
                .onChange(of: proxy.size.height) { _, newHeight in
                    let oldHeight = realHeight
                    contentHeight = newHeight
                    
                    if oldHeight != realHeight {
                        model.adjustPanelSize()
                    } else {
                        scrollToBottom(using: scrollProxy)
                    }
                }
        }
    }
}

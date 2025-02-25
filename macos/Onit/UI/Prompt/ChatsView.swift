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
    
    @State private var contentHeight: CGFloat = 0
    @State private var lastPromptHeight: CGFloat = 0
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0
    @State private var lastScrollTime: Date = .now

    private var chatsID: Int? {
        model.currentChat?.hashValue
    }
    private let scrollDebounceInterval: TimeInterval = 0.1
    
    var maxHeight: CGFloat {
        guard !model.resizing, screenHeight != 0 else { return 0 }

        return screenHeight - model.headerHeight -
            model.inputHeight - model.setUpHeight -
            model.systemPromptHeight - 100
    }
    
    var realHeight: CGFloat {
        isPanelExpanded ? maxHeight : min(contentHeight, maxHeight)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: -16) {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        if prompt == model.currentPrompts?.last {
                            PromptView(prompt: prompt)
                                .background(lastPromptHeightReader(scrollProxy: proxy))
                        } else {
                            PromptView(prompt: prompt)
                        }
                    }
                }
                .id(chatsID)
                .background(heightReader)
            }
            .screenHeight(binding: $screenHeight)
            .frame(
                minHeight: 0,
                idealHeight: realHeight,
                maxHeight: maxHeight,
                alignment: .top
            )
            .onChange(of: model.currentChat, initial: true) { old, new in
                if old == nil && new != nil {
                    return
                }
                let now = Date()
                if now.timeIntervalSince(lastScrollTime) >= scrollDebounceInterval {
                    lastScrollTime = now
                    withAnimation {
                        proxy.scrollTo(chatsID, anchor: .bottom)
                    }
                }
            }
        }
    }

    var heightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    let oldHeight = realHeight
                    contentHeight = proxy.size.height
                    
                    if oldHeight != realHeight {
                        model.adjustPanelSize()
                    }
                }
                .onChange(of: proxy.size.height) {
                    let oldHeight = realHeight
                    contentHeight = proxy.size.height

                    if oldHeight != realHeight {
                        model.adjustPanelSize()
                    }
                    
                    // When new chat, there is no prompt so reset the lastPromptHeight
                    if proxy.size.height == 0 {
                        lastPromptHeight = 0
                    }
                }
        }
    }
    
    func lastPromptHeightReader(scrollProxy: ScrollViewProxy) -> some View {
        GeometryReader { promptProxy in
            Color.clear
                .onChange(of: promptProxy.size.height) { _, newHeight in
                    if lastPromptHeight != newHeight {
                        lastPromptHeight = newHeight
                        
                        let now = Date()
                        if now.timeIntervalSince(lastScrollTime) >= scrollDebounceInterval {
                            lastScrollTime = now

                            scrollProxy.scrollTo(chatsID, anchor: .bottom)
                        }
                    }
                }
        }
    }
}

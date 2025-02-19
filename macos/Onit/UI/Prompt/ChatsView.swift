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

    private let chatsID = "chats"
    private let scrollDebounceInterval: TimeInterval = 0.1
    
    var maxHeight: CGFloat {
        guard !model.resizing, screenHeight != 0 else { return 0 }
        let availableHeight =
            screenHeight
            - model.headerHeight - model.inputHeight - model.setUpHeight - 100
        return availableHeight
    }
    
    var realHeight: CGFloat {
        isPanelExpanded ? maxHeight : min(contentHeight, maxHeight)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: -16) {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        PromptView(prompt: prompt)
                            .background(
                                Group {
                                    if prompt == model.currentPrompts?.last {
                                        lastPromptHeightReader(scrollProxy: proxy)
                                    }
                                }
                            )
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
            .onChange(of: model.currentPrompts?.count, initial: true) {
                withAnimation {
                    proxy.scrollTo(chatsID, anchor: .bottom)
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

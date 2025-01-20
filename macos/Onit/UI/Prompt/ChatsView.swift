//
//  ChatsView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import SwiftUI

struct ChatsView: View {
    @Environment(\.model) var model
    @State private var windowTopOffset: CGFloat = 0

    let chatsID = "chats"

    var maxHeight: CGFloat {
        guard !model.resizing else { return 0 }
        let screenHeight = NSScreen.main!.frame.height
        let availableHeight = screenHeight - windowTopOffset - model.headerHeight - model.inputHeight - model.setUpHeight
        return availableHeight
    }

    var contentHeight: CGFloat {
        max(1, model.contentHeight)
    }

    var lastGenerationSate: GenerationState {
        model.currentPrompts?.last?.generationState ?? .done
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: -16) {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        PromptView(prompt: prompt)
                            .background {
                                if prompt == model.currentPrompts?.last {
                                    heightReader
                                }
                            }
                    }
                }
                .id(chatsID)
            }
            .onChange(of: model.currentPrompts?.count) {
                withAnimation {
                    proxy.scrollTo(chatsID, anchor: .bottom)
                }
            }
            .onChange(of: lastGenerationSate) {
                withAnimation {
                    proxy.scrollTo(chatsID, anchor: .bottom)
                }
            }
        }
        .frame(
            minHeight: min(maxHeight, contentHeight),
            idealHeight: min(maxHeight, contentHeight),
            maxHeight: maxHeight
        )
        .onAppear {
            updateWindowTopOffset()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)) { _ in
            updateWindowTopOffset()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            updateWindowTopOffset()
        }
    }

    func updateWindowTopOffset() {
        if let window = model.panel {
            let screenHeight = NSScreen.main!.frame.height
            let windowTopY = window.frame.origin.y + window.frame.size.height
            windowTopOffset = screenHeight - windowTopY
        }
    }

    var heightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    model.contentHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) {
                    model.contentHeight = proxy.size.height
                }
        }
    }
}

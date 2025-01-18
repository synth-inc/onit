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
        let screenHeight = NSScreen.main!.frame.height
        let availableHeight = screenHeight - windowTopOffset - model.headerHeight - model.inputHeight
        return availableHeight
    }

    var contentHeight: CGFloat {
        model.contentHeight
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        PromptView(prompt: prompt)
                    }
                }
                .id(chatsID)
                .background {
                    heightReader
                }
            }
            .onChange(of: model.currentPrompts?.count) {
                withAnimation {
                    proxy.scrollTo(chatsID, anchor: .bottom)
                }
            }
        }
        .frame(height: min(maxHeight, contentHeight))
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
                .onChange(of: proxy.size.height) { _, newHeight in
                    model.contentHeight = newHeight
                }
        }
    }
}

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
    @State private var contentHeight: CGFloat = 0
    @State private var lastPromptHeight: CGFloat = 0
    @Default(.isPanelExpanded) var isPanelExpanded: Bool

    let chatsID = "chats"

    var maxHeight: CGFloat {
        guard !model.resizing else { return 0 }
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 0
        let availableHeight =
            screenHeight
            - model.headerHeight - model.inputHeight - model.setUpHeight
        return availableHeight
    }
    
    var realHeight: CGFloat {
        isPanelExpanded ? maxHeight : min(contentHeight, maxHeight)
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
            .frame(
                minHeight: realHeight,
                idealHeight: realHeight,
                alignment: .top
            )
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
                        withAnimation {
                            scrollProxy.scrollTo(chatsID, anchor: .bottom)
                        }
                    }
                }
        }
    }
}

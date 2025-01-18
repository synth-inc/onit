//
//  ChatsView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/17/25.
//

import SwiftUI

struct ChatsView: View {
    @Environment(\.model) var model

    let chatsID = "chats"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack() {
                    ForEach(model.currentPrompts ?? []) { prompt in
                        PromptView(prompt: prompt)
                    }
                }
                .id(chatsID)
            }
            .onChange(of: model.currentPrompts?.count) {
                withAnimation {
                    proxy.scrollTo(chatsID, anchor: .bottom)
                }
            }
        }
    }
}

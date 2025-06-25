//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.windowState) private var windowState
    let chat: Chat
    let index: Int
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.prompts.first?.instruction ?? "Empty chat")
                    .appFont(.medium14)
                    .foregroundStyle(.white)
                    .truncateText()
                
                Text("\(chat.prompts.count) messages")
                    .appFont(.medium12)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                windowState?.setChat(chat: chat, index: index)
            }

            HStack(spacing: 4) {
                IconButton(
                    icon: .remove,
                    iconSize: 12,
                    action: {
                        // Only proceed if windowState is available and deletion hasn't failed
                        guard let windowState = windowState else { return }
                        
                        if !windowState.deleteChatFailed {
                            windowState.deleteChat(chat: chat)
                        }
                    },
                    tooltipPrompt: "Delete"
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .addButtonEffects(
            background: .gray700,
            hoverBackground: .gray600,
            cornerRadius: 6,
            isHovered: $isHovered,
            isPressed: $isPressed,
            action: {
                windowState?.setChat(chat: chat, index: index)
            }
        )
    }
}

#if DEBUG
    #Preview {
        // TODO make samples
        //        HistoryRowView(chat: .sample)
    }
#endif

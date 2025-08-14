//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.windowState) private var windowState
    
    @State private var showDelete: Bool = false

    var chat: Chat
    var index: Int

    var body: some View {
        TextButton(
            text: getPromptText()
        ) {
            Group {
                if showDelete { deleteButton }
                else { chatResponseCount }
            }
        } action: {
            windowState?.setChat(chat: chat, index: index)
        }
        .onHover { hovering in showDelete = hovering }
    }
    
    var chatResponseCount: some View {
        Text("\(chat.responseCount)")
            .appFont(.medium13)
            .monospacedDigit()
            .foregroundStyle(Color.S_2)
    }
    
    var deleteButton: some View {
        HStack(alignment: .center) {
            Text(windowState?.deleteChatFailed == true ? "Delete failed" : "")
                .foregroundColor(Color.red500)
            
            Image(systemName: "trash")
                .renderingMode(.template)
                .foregroundColor(Color.S_2)
                .frame(width: 14, height: 14)
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            // We want the padding around the button to also be a tap target
            guard let windowState = windowState else { return }
            if !windowState.deleteChatFailed {
                windowState.deleteChat(chat: chat)
            }
        }
    }
    
    private func getPromptText() -> String {
        guard let firstPrompt = chat.prompts.first,
              !firstPrompt.responses.isEmpty,
              firstPrompt.generationIndex < firstPrompt.responses.count else {
            return "Empty"
        }
        
        return firstPrompt.responses[firstPrompt.generationIndex].instruction ?? ""
    }
}

#if DEBUG
    #Preview {
        // TODO make samples
        //        HistoryRowView(chat: .sample)
    }
#endif

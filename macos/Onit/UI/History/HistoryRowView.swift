//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.model) var model
    
    @State private var showDelete: Bool = false

    var chat: Chat
    var index: Int

    var body: some View {
        Button {
            model.setChat(chat: chat, index: index)
        } label: {
            HStack {
                Text(HistoryRowView.getPromptText(chat: chat))
                    .appFont(.medium16)
                    .foregroundStyle(.FG)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Group {
                    if showDelete { deleteButton }
                    else { chatResponseCount }
                }
            }
            .padding(.leading, 10)
        }
        .frame(height: 36)
        .buttonStyle(HoverableButtonStyle(background: true))
        .onHover { hovering in showDelete = hovering }
    }
    
    var chatResponseCount: some View {
        Text("\(chat.responseCount)")
            .appFont(.medium13)
            .monospacedDigit()
            .foregroundStyle(.gray200)
            .padding(.trailing, 10)
    }
    
    var deleteButton: some View {
        let deletionFailed = model.deleteChatFailedQueue.keys.contains(chat.id)
        
        return HStack(alignment: .center) {
            Text(deletionFailed ? "Delete failed" : "")
                .foregroundColor(Color.red)
            
            Image(systemName: "trash")
                .frame(width: 14, height: 14)
                .padding(.trailing, 10)
                .opacity(deletionFailed ? 0.5 : 1)
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            if !deletionFailed { model.addChatToDeleteQueue(chat: chat) }
        }
    }
    
    static func getPromptText(chat: Chat) -> String {
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
        ModelContainerPreview {
            // TODO make samples
            //        HistoryRowView(chat: .sample)
        }
    }
#endif

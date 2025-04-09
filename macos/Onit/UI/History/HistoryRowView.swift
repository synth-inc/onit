//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.model) var model
    
    @State private var showDeleteButton: Bool = false
    @State private var deleteButtonHovered: Bool = false

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
                    if showDeleteButton { deleteButton }
                    else { chatResponseCount }
                }
            }
            .padding(.leading, 10)
        }
        .frame(height: 36)
        .buttonStyle(HoverableButtonStyle(background: true))
        .onHover { hovering in showDeleteButton = hovering }
    }
    
    var chatResponseCount: some View {
        Text("\(chat.responseCount)")
            .appFont(.medium13)
            .monospacedDigit()
            .foregroundStyle(.gray200)
            .padding(.trailing, 10)
    }
    
    var deleteButton: some View {
        Button {
            if let pendingDeletedHistoryItem = model.chatQueuedForDeletion {
                model.deleteChat(chat: pendingDeletedHistoryItem)
            }
            
            if !model.chatDeletionFailed { model.chatQueuedForDeletion = chat }
            
            model.historyDeleteToastDismissed = false
            model.chatDeletionTimePassed = 0
        } label: {
            Image(systemName: "trash")
                .resizable()
                .frame(width: 14, height: 14)
                .padding(.horizontal, 10)
                .foregroundColor(deleteButtonHovered ? .gray100 : .gray200)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxHeight: .infinity)
        .onHover { hovering in deleteButtonHovered = hovering }
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

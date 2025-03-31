//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
    @Environment(\.model) var model
    @Environment(\.modelContext) var modelContext
    
    @State private var showDelete: Bool = false
    @State private var deleteFailed: Bool = false

    var chat: Chat

    var body: some View {
        Button {
            model.currentChat = chat
            model.currentPrompts = chat.prompts
            model.showHistory = false
        } label: {
            HStack {
                Text(chat.prompts.first?.instruction ?? "")
                    .appFont(.medium16)
                    .foregroundStyle(.FG)
                
                Spacer()
                
                Group {
                    if showDelete { deleteButton }
                    else { chatResponseCount }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .buttonStyle(HoverableButtonStyle(background: true))
        .onHover { hovering in showDelete = hovering }
    }
    
    var chatResponseCount: some View {
        Text("\(chat.responseCount)")
            .appFont(.medium13)
            .monospacedDigit()
            .foregroundStyle(.gray200)
    }
    
    var deleteButton: some View {
        HStack(alignment: .center) {
            Text(deleteFailed ? "Delete failed" : "")
                .foregroundColor(Color.red)
            
            Image(systemName: "trash")
                .frame(width: 14, height: 14)
                .onTapGesture {
                    deleteChat()
                }
        }
    }
    
    func deleteChat() {
        do {
            deleteFailed = false
            modelContext.delete(chat)
            try modelContext.save()
        } catch {
            deleteFailed = true
            
            #if DEBUG
            print("Chat delete error: \(error)")
            #endif
        }
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

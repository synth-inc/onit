//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import Defaults
import SwiftUI

struct HistoryRowView: View {
    @Default(.incognitoModeEnabled) var incognitoModeEnabled
    
    @Environment(\.model) var model
    
    @State private var showDelete: Bool = false

    var chat: Chat
    var index: Int

    var body: some View {
        Button {
            incognitoModeEnabled = false
            model.setChat(chat: chat, index: index)
        } label: {
            HStack {
                Text(getPromptText())
                    .appFont(.medium16)
                    .foregroundStyle(.FG)
                
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
        HStack(alignment: .center) {
            Text(model.deleteChatFailed ? "Delete failed" : "")
                .foregroundColor(Color.red)
            
            Image(systemName: "trash")
                .frame(width: 14, height: 14)
                .padding(.trailing, 10)
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            // We want the padding around the button to also be a tap target
            if !model.deleteChatFailed {
                model.deleteChat(chat: chat)
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
        ModelContainerPreview {
            // TODO make samples
            //        HistoryRowView(chat: .sample)
        }
    }
#endif

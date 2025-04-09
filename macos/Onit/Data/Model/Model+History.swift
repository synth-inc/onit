//
//  Model+History.swift
//  Onit
//
//  Created by Loyd Kim on 3/31/25.
//

import Foundation

extension OnitModel {
    func setChat(chat: Chat, index: Int) {
        currentChat = chat
        currentPrompts = chat.prompts
        showHistory = false
        historyIndex = index
    }
    
    func deleteChat(chat: Chat) {
        do {
            chatDeletionFailed = false
            container.mainContext.delete(chat)
            try container.mainContext.save()
        } catch {
            chatDeletionFailed = true
            chatDeletionTimePassed = 0
        }
        
        chatQueuedForDeletion = nil
    }
}

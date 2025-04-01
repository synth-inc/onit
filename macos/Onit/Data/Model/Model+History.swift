//
//  Model+History.swift
//  Onit
//
//  Created by Loyd Kim on 3/31/25.
//

extension OnitModel {
    func setChat(chat: Chat, index: Int) {
        currentChat = chat
        currentPrompts = chat.prompts
        showHistory = false
        historyIndex = index
    }
    
    func deleteChat(chat: Chat) {
        do {
            deleteChatFailed = false
            container.mainContext.delete(chat)
            try container.mainContext.save()
        } catch {
            deleteChatFailed = true
            
            #if DEBUG
            print("Chat delete error: \(error)")
            #endif
        }
    }
}

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
    
    /// Delete Queue
    
    func deleteChat(chat: Chat) async {
        do {
            await removeChatFromDeleteFailedQueue(chatId: chat.id, waitSeconds: 0)
            
            try await Task.sleep(for: .seconds(deleteChatDurationSeconds))
            try Task.checkCancellation()
            
            removeChatFromDeleteQueue(chatId: chat.id)
            
            container.mainContext.delete(chat)
            try container.mainContext.save()
        } catch is CancellationError {
            // This catch clause is only meant to prevent the system from mistaking
            // the cancellation of chat deletion tasks as errors. Cancellation is fine.
        } catch {
            addChatToDeleteFailedQueue(chatId: chat.id)
            
            #if DEBUG
            print("Chat delete error: \(error)")
            #endif
        }
    }
    
    func addChatToDeleteQueue(chat: Chat) {
        let deleteChatQueueItem = DeleteChatQueueItem(
            name: HistoryRowView.getPromptText(chat: chat),
            chatId: chat.id,
            startTime: Date(),
            deleteChatTask: Task { await deleteChat(chat: chat) }
        )
        deleteChatQueue.append(deleteChatQueueItem)
    }
    
    func removeChatFromDeleteQueue(chatId: DeleteChatId) {
        if let queueItemIndex = deleteChatQueue.firstIndex(where: { $0.chatId == chatId }) {
            deleteChatQueue[queueItemIndex].deleteChatTask.cancel()
            deleteChatQueue.remove(at: queueItemIndex)
        }
    }
    
    func emptyDeleteChatQueue() {
        for item in deleteChatQueue { item.deleteChatTask.cancel() }
        deleteChatQueue.removeAll()
    }
    
    /// Delete Failed Queue
    
    func addChatToDeleteFailedQueue(chatId: DeleteChatId) {
        deleteChatFailedQueue[chatId] = Task {
            await removeChatFromDeleteFailedQueue(chatId: chatId, waitSeconds: 2)
        }
    }
    
    func removeChatFromDeleteFailedQueue(chatId: DeleteChatId, waitSeconds: Int) async {
        try? await Task.sleep(for: .seconds(waitSeconds))
        try? Task.checkCancellation()
        
        if let deleteFailedTask = deleteChatFailedQueue[chatId] {
            deleteFailedTask.cancel()
        }
        
        deleteChatFailedQueue.removeValue(forKey: chatId)
    }
}

//
//  HistoryView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.model) var model
    
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @State private var searchQuery: String = ""
    @State private var dismissedDeleteNotifications: Set<PersistentIdentifier> = []

    var filteredChats: [Chat] {
        let chatsNotQueuedForDeletion = chats.filter { chat in
            chat.id != model.chatQueuedForDeletion?.id
        }
        
        if searchQuery.isEmpty {
            return chatsNotQueuedForDeletion
        } else {
            return chatsNotQueuedForDeletion.filter {
                $0.fullText.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var groupedChats: [String: [Chat]] {
        Dictionary(grouping: filteredChats) { chat in
            let calendar = Calendar.current
            let now = Date()

            if calendar.isDateInToday(chat.timestamp) {
                return "Today"
            } else if calendar.isDate(chat.timestamp, equalTo: now, toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(chat.timestamp, equalTo: now, toGranularity: .month) {
                return "This Month"
            } else {
                return "Earlier"
            }
        }
    }

    var sortedChats: [(key: String, value: [Chat])] {
        groupedChats.sorted(by: { $0.key > $1.key })
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                HistoryTitle()
                HistorySearchView(text: $searchQuery)
                
                if sortedChats.isEmpty { emptyText }
                else { historyRows }
            }
            .frame(width: 350)
            .background(.BG)
            
            historyDeleteToast
        }
    }
    
    var emptyText: some View {
        Text("No chats")
            .foregroundStyle(.gray200)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
    }
    
    var historyRows: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Spacer().frame(height: 12)
                ForEach(sortedChats, id: \.key) { section, chats in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section)
                            .appFont(.medium13)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 4)
                            .padding(.leading, 4)

                        ForEach(Array(chats.enumerated()), id: \.element.id) { index, chat in
                            HistoryRowView(chat: chat, index: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }
    
    @ViewBuilder
    var historyDeleteToast: some View {
        if let chat = model.chatQueuedForDeletion {
            ZStack {
                HistoryDeleteToast(
                    text: "Item deleted",
                    chat: chat
                )
            }.attachHistoryDeleteToastStyles()
        } else if model.chatDeletionFailed {
            ZStack {
                HistoryDeleteToast(
                    text: "Failed to delete. Please retry",
                    chat: nil
                )
            }.attachHistoryDeleteToastStyles()
        }
    }

}

extension View {
    func attachHistoryDeleteToastStyles() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.horizontal, 12)
    }
}

#Preview {
    HistoryView()
}

//
//  HistoryView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) var windowState
    @Query(sort: \Chat.timestamp, order: .reverse) private var allChats: [Chat]
    @State private var searchQuery: String = ""
    
    private var chats: [Chat] {
        let chatsFilteredByAccount = allChats
            .filter { $0.accountId == appState.account?.id }
        
        return PanelStateCoordinator.shared.filterHistoryChats(chatsFilteredByAccount)
    }
    
    var filteredChats: [Chat] {
        if searchQuery.isEmpty {
            return chats
        } else {
            return chats.filter {
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
        MenuList(
            header: MenuHeader(title: "History") {
                IconButton(
                    icon: .cross,
                    iconSize: 10
                ) {
                    windowState?.showHistory = false
                }
            },
            search: MenuList.Search(query: $searchQuery)
        ) {
            MenuSection(maxScrollHeight: 295) {
                if sortedChats.isEmpty { emptyText }
                else { historyRows }
            }
        }
    }
}

// MARK: - Child Components

extension HistoryView {
    private var emptyText: some View {
        Text("No prompts found")
            .foregroundStyle(Color.S_2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }
    
    private var historyRows: some View {
        LazyVStack(alignment: .leading) {
            ForEach(sortedChats, id: \.key) { section, chats in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section)
                        .appFont(.medium13)
                        .foregroundStyle(Color.S_0.opacity(0.6))
                        .padding(.top, 4)
                        .padding(.leading, 4)

                    ForEach(Array(chats.enumerated()), id: \.element.id) { index, chat in
                        HistoryRowView(chat: chat, index: index)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}

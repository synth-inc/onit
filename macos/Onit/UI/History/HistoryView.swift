//
//  HistoryView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.windowState) var windowState
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @State private var searchQuery: String = ""

    var filteredChats: [Chat] {
        let appBundleIdentifier = windowState.trackedWindow?.pid.bundleIdentifier
        let bundleIdentifierChats = chats.filter {
            $0.appBundleIdentifier == appBundleIdentifier
        }
        
        if searchQuery.isEmpty {
            return bundleIdentifierChats
        } else {
            return bundleIdentifierChats.filter {
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
        VStack(spacing: 0) {
            HistoryTitle()
            HistorySearchView(text: $searchQuery)
            
            if sortedChats.isEmpty { emptyText }
            else { historyRows }
        }
        .frame(width: 350)
        .background(.BG)
    }
    
    var emptyText: some View {
        Text("No prompts found")
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

}

#Preview {
    HistoryView()
}

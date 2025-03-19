//
//  HistoryView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @State private var searchQuery: String = ""
    @State private var debouncedQuery: String = ""
    @State private var isShowing = false
    
    var filteredChats: [Chat] {
        if debouncedQuery.isEmpty {
            return chats
        } else {
            return chats.filter {
                $0.fullText.localizedCaseInsensitiveContains(debouncedQuery)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            HistorySearchView(text: $searchQuery, onSearch: { debouncedText in
                debouncedQuery = debouncedText
            })
                .padding(.horizontal, 4)

            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(sortedChats, id: \.key) { section, chats in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section)
                                .appFont(.medium13)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 4)
                                .padding(.leading, 4)

                            ForEach(chats) { chat in
                                HistoryRowView(chat: chat)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 244)
        }
        .frame(width: 300)
        .background(Color.BG)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray800, lineWidth: 1)
        )
        .scaleEffect(isShowing ? 1 : 0.8)
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.2)) {
                isShowing = true
            }
        }
        .environment(\.modelContext, modelContext)
    }
}

#Preview {
    HistoryView()
}

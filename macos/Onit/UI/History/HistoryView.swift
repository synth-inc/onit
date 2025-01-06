//
//  HistoryView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/3/24.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \Prompt.timestamp, order: .reverse) var prompts: [Prompt]

    @State private var searchQuery: String = ""

    var filteredPrompts: [Prompt] {
        if searchQuery.isEmpty {
            return prompts
        } else {
            return prompts.filter {
                $0.text.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var groupedPrompts: [String: [Prompt]] {
        Dictionary(grouping: filteredPrompts) { prompt in
            let calendar = Calendar.current
            let now = Date()

            if calendar.isDateInToday(prompt.timestamp) {
                return "Today"
            } else if calendar.isDate(prompt.timestamp, equalTo: now, toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(prompt.timestamp, equalTo: now, toGranularity: .month) {
                return "This Month"
            } else {
                return "Earlier"
            }
        }
    }

    var sortedPrompts: [(key: String, value: [Prompt])] {
        groupedPrompts.sorted(by: { $0.key > $1.key })
    }

    var body: some View {
        VStack(spacing: 0) {
            HistoryTitle()
            HistorySearchView(text: $searchQuery)
            ScrollView {
                LazyVStack(alignment: .leading) {
                    Spacer().frame(height: 12)
                    ForEach(sortedPrompts, id: \.key) { section, prompts in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section)
                                .appFont(.medium13)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 4)
                                .padding(.leading, 4)

                            ForEach(prompts) { prompt in
                                HistoryRowView(prompt: prompt)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

}

#Preview {
    HistoryView()
}

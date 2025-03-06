import XCTest
@testable import Onit

final class HistoryViewTests: XCTestCase {
    func testHistoryViewFiltering() {
        let container = try! ModelContainer(for: Chat.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        // Create test chats
        let chat1 = Chat(timestamp: Date(), instruction: "Test chat 1")
        let chat2 = Chat(timestamp: Date(), instruction: "Test chat 2")
        let chat3 = Chat(timestamp: Date(), instruction: "Different chat")

        context.insert(chat1)
        context.insert(chat2)
        context.insert(chat3)

        // Create HistoryView
        let historyView = HistoryView()

        // Test filtering with empty search query
        XCTAssertEqual(historyView.filteredChats.count, 3, "All chats should be visible when search query is empty")

        // Test filtering with search query
        historyView.searchQuery = "Test"
        XCTAssertEqual(historyView.filteredChats.count, 2, "Only chats containing 'Test' should be visible")

        // Test filtering with non-matching query
        historyView.searchQuery = "nonexistent"
        XCTAssertEqual(historyView.filteredChats.count, 0, "No chats should be visible with non-matching query")
    }

    func testHistoryViewGrouping() {
        let container = try! ModelContainer(for: Chat.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let calendar = Calendar.current
        let now = Date()

        // Create test chats with different dates
        let todayChat = Chat(timestamp: now, instruction: "Today's chat")
        let yesterdayChat = Chat(timestamp: calendar.date(byAdding: .day, value: -1, to: now)!, instruction: "Yesterday's chat")
        let lastWeekChat = Chat(timestamp: calendar.date(byAdding: .day, value: -7, to: now)!, instruction: "Last week's chat")
        let lastMonthChat = Chat(timestamp: calendar.date(byAdding: .month, value: -1, to: now)!, instruction: "Last month's chat")

        context.insert(todayChat)
        context.insert(yesterdayChat)
        context.insert(lastWeekChat)
        context.insert(lastMonthChat)

        // Create HistoryView
        let historyView = HistoryView()

        // Test grouping
        let groups = historyView.groupedChats
        XCTAssertNotNil(groups["Today"], "Should have a 'Today' group")
        XCTAssertEqual(groups["Today"]?.count, 1, "Today's group should have 1 chat")
        XCTAssertEqual(groups["Earlier"]?.count, 3, "Earlier group should have 3 chats")
    }
}

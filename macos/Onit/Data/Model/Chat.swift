import Foundation
import SwiftData

@Model
final class Chat {
    var systemPrompt: SystemPrompt?
    var prompts: [Prompt]
    var timestamp: Date
    
    var appBundleIdentifier: String?
    var windowHash: UInt?
    var accountId: Int?

    init(
        systemPrompt: SystemPrompt,
        prompts: [Prompt] = [],
        timestamp: Date = Date(),
        trackedWindow: TrackedWindow? = nil,
        accountId: Int?
    ) {
        self.systemPrompt = systemPrompt
        self.prompts = prompts
        self.timestamp = timestamp
        self.appBundleIdentifier = trackedWindow?.pid.bundleIdentifier
        self.windowHash = trackedWindow?.hash
        self.accountId = accountId
    }

    var isEmpty: Bool {
        prompts.isEmpty
    }

    var responseCount: Int {
        prompts.reduce(0) { $0 + ($1.responses.count) }
    }

    var fullText: String {
        prompts.map { $0.fullText }.joined(separator: "\n")
    }
}

extension Chat {
    @MainActor static let sample = Chat(systemPrompt: .outputOnly, prompts: [Prompt.sample], accountId: nil)
}

import Foundation
import SwiftData

@Model
final class Chat {
    var systemPrompt: SystemPrompt?
    var prompts: [Prompt]
    var timestamp: Date
    var windowPid: pid_t?

    init(systemPrompt: SystemPrompt, prompts: [Prompt] = [], timestamp: Date = Date(), windowPid: pid_t? = nil) {
        self.systemPrompt = systemPrompt
        self.prompts = prompts
        self.timestamp = timestamp
        self.windowPid = windowPid
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
    @MainActor static let sample = Chat(systemPrompt: .outputOnly, prompts: [Prompt.sample])
}

import Foundation
import SwiftData

@Model
final class Chat {
    var prompts: [Prompt]
    var timestamp: Date
    
    init(prompts: [Prompt] = [], timestamp: Date = Date()) {
        self.prompts = prompts
        self.timestamp = timestamp
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

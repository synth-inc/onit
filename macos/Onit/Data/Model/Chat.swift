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
}
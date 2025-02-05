import Defaults
import Foundation
import SwiftData

struct CustomProvider: Codable, Identifiable, Hashable, Defaults.Serializable {
    var id: String { name }
    
    var name: String
    var baseURL: String
    var token: String
    var models: [String]
    var isEnabled: Bool

    init(name: String, baseURL: String, token: String, models: [String]) {
        self.name = name
        self.baseURL = baseURL
        self.token = token
        self.models = models
        self.isEnabled = true
    }

    static func == (lhs: CustomProvider, rhs: CustomProvider) -> Bool {
        return lhs.name == rhs.name && lhs.baseURL == rhs.baseURL
            && lhs.token == rhs.token && lhs.models == rhs.models
            && lhs.isEnabled == rhs.isEnabled
    }
}

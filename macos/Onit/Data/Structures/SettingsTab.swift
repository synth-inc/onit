import Foundation

enum SettingsTab: String {
    case general
    case models
    case prompts
    case shortcuts
    case accessibility
    case webSearch
    case about
    case account
    #if DEBUG
        case debug
    #endif
}

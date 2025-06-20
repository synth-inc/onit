import Foundation

enum SettingsTab: String {
    case general
    case models
    case prompts
    case shortcuts
    case accessibility
    case webSearch
    case about
    #if DEBUG
        case database
        case debug
        case account
    #endif
}

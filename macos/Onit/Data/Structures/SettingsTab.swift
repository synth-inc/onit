import Foundation

enum SettingsTab: String {
    case models
    case shortcuts
    case accessibility
    case about
    #if DEBUG
    case debug
    #endif
}

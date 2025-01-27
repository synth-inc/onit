import Foundation

enum SettingsTab: String {
    case models
    case shortcuts
    case about
    #if DEBUG
    case debug
    #endif
}
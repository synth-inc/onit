import Foundation

enum SettingsTab: String {
    case general
    case models
    case shortcuts
    case about
    #if DEBUG
    case debug
    #endif
}
import Foundation

enum SettingsTab: String {
  case general
  case models
  case shortcuts
  case accessibility
  case about
  #if DEBUG
    case debug
  #endif
}

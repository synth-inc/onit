import Foundation

enum WindowSizeMode: String, Codable {
    case `default`   // Always top-right with default size
    case userLast    // User's last position and size
    case fullScreen  // Full screen mode
}
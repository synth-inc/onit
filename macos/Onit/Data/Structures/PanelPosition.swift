import Foundation

enum PanelPosition: String, CaseIterable, Codable {
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    
    var systemImage: String {
        switch self {
        case .topLeft:
            return "arrow.up.left.square"
        case .topCenter:
            return "arrow.up.square"
        case .topRight:
            return "arrow.up.right.square"
        }
    }
}
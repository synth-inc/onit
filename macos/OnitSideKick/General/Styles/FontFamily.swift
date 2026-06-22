//
//  FontFamily.swift
//  Onit
//
//  Created by Loyd Kim on 3/25/26.
//

import SwiftUI

enum FontFamily: String {
    case system
    case inter = "Inter"
    case libreBaskerville = "Libre Baskerville"
    case code = "Sometype Mono"

    /// Returns the SwiftUI `Font` for this family at the given size.
    func font(size: CGFloat) -> Font {
        switch self {
        case .system:
            return .system(size: size)
        default:
            return .custom(self.rawValue, size: size)
        }
    }
}

//
//  HoverPointerStyle.swift
//  Onit
//
//  Created by Kévin Naudin on 11/06/2026.
//

import SwiftUI

/// Deployment-target-safe stand-in for `PointerStyle` (macOS 15+) so views can
/// store a pointer style while the app still deploys to macOS 14. Resolves to
/// the real `PointerStyle` at runtime on macOS 15+, and is a no-op on 14.
enum HoverPointerStyle {
    case link

    @available(macOS 15.0, *)
    fileprivate var systemStyle: PointerStyle {
        switch self {
        case .link: return .link
        }
    }
}

extension View {
    @ViewBuilder
    func hoverPointerStyle(_ style: HoverPointerStyle?) -> some View {
        if #available(macOS 15.0, *) {
            self.pointerStyle(style?.systemStyle)
        } else {
            self
        }
    }
}

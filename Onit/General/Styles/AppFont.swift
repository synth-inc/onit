//
//  AppFont.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

enum AppFont {
    case medium12
    case medium13
    case medium14
    case medium16

    var font: Font {
        .custom(fontName, size: originalPointSize)
    }

    var nsFont: NSFont {
        NSFont(name: fontName, size: originalPointSize) ?? systemUIFont
    }

    var systemUIFont: NSFont {
        .systemFont(ofSize: originalPointSize)
    }

    var lineSpacing: CGFloat {
        guard originalLineSpacing > 0 else { return 0 }
        let unscaledFont = NSFont.systemFont(ofSize: originalLineSpacing)
        let userFontSize = NSFont.systemFontSize(for: .regular)
        let scaleFactor = userFontSize / NSFont.systemFontSize
        let scaledFont = NSFont(
            descriptor: unscaledFont.fontDescriptor, size: unscaledFont.pointSize * scaleFactor)
        return scaledFont?.pointSize ?? originalLineSpacing
    }

    var kearning: CGFloat {
        return 0
    }

    // MARK: - Utilities
    private var fontName: String {
        return "Inter"
    }

    private var originalPointSize: CGFloat {
        switch self {
        case .medium12:
            return 12
        case .medium13:
            return 13
        case .medium14:
            return 14
        case .medium16:
            return 16
        }
    }

    private var originalLineSpacing: CGFloat {
        switch self {
        case .medium12:
            return 1.5
        case .medium13:
            return 1.75
        case .medium14:
            return 2
        case .medium16:
            return 2.25
        }
    }
}
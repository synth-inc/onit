//
//  AppFont.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import Defaults
import SwiftUI

@MainActor
enum AppFont {
  case medium10
  case medium12
  case medium13
  case medium14
  case medium16
  case code

  var font: Font {
    .custom(fontName, size: pointSize)
  }

  var nsFont: NSFont {
    NSFont(name: fontName, size: pointSize) ?? systemUIFont
  }

  var systemUIFont: NSFont {
    .systemFont(ofSize: pointSize)
  }

  private var pointSize: CGFloat {
    let baseFontSize = Defaults[.fontSize]
    switch self {
    case .medium10:
      return baseFontSize - 4
    case .medium12:
      return baseFontSize - 2
    case .medium13:
      return baseFontSize - 1
    case .medium14:
      return baseFontSize
    case .medium16:
      return baseFontSize + 2
    case .code:
      return baseFontSize
    }
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
    switch self {
    case .code:
      return "Sometype Mono"
    default:
      return "Inter"
    }
  }

  private var originalPointSize: CGFloat {
    switch self {
    case .medium10:
      return 10
    case .medium12:
      return 12
    case .medium13:
      return 13
    case .medium14:
      return 14
    case .medium16:
      return 16
    case .code:
      return 16
    }
  }

  private var originalLineSpacing: CGFloat {
    switch self {
    case .medium10:
      return 1
    case .medium12:
      return 1.5
    case .medium13:
      return 1.75
    case .medium14:
      return 2
    case .medium16:
      return 2.25
    case .code:
      return 8
    }
  }
}

//
//  ColorStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import SwiftUI

extension Color {
    /// For easily converting hex colors in design files.
    init?(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        
        guard hexSanitized.count == 6 || alpha < 0 || alpha > 1
        else { return nil }
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        // Accounting for the case of 8-character hexcodes (last 2 = alpha values).
        var computedAlpha: Double = alpha
        if hexSanitized.count == 8 {
            computedAlpha = Double((rgb >> 24) & 0xFF) / 255.0
        }
        
        self.init(red: red, green: green, blue: blue, opacity: computedAlpha)
    }
}


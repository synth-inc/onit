//
//  TooltipModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 10/30/24.
//

import SwiftUI

struct TooltipModifier: ViewModifier {
    var tooltip: Tooltip
    var background: Bool

    func body(content: Content) -> some View {
        content
            .buttonStyle(HoverableButtonStyle(tooltip: tooltip, background: background))
    }
}

extension View {
    func tooltip(prompt: String, shortcut: Tooltip.Shortcut = .none, background: Bool = true)
        -> some View
    {
        modifier(
            TooltipModifier(
                tooltip: Tooltip(prompt: prompt, shortcut: shortcut), background: background))
    }
}

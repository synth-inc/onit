//
//  TooltipHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 7/8/25.
//

import SwiftUI

struct TooltipHelpers {
    @MainActor
    static func setTooltipOnHover(
        isHovering: Bool,
        tooltipPrompt: String?,
        tooltipShortcut: Tooltip.Shortcut = .none,
        tooltipConfig: TooltipConfig? = nil
    ) {
        if tooltipPrompt != nil {
            if isHovering {
                TooltipManager.shared.setTooltip(
                    Tooltip(
                        prompt: tooltipPrompt!,
                        shortcut: tooltipShortcut
                    ),
                    tooltipConfig: tooltipConfig
                )
            } else {
                TooltipManager.shared.setTooltip(nil)
            }
        }
    }
}

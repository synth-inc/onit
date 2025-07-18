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
                        shortcut: tooltipShortcut,
                    ),
                    tooltipConfig: tooltipConfig,
                    delayStart: 0.4,
                    delayEnd: 0
                )
            } else {
                TooltipManager.shared.setTooltip(
                    nil,
                    delayEnd: 0
                )
            }
        }
    }
}

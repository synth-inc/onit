//
//  TooltipHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 7/8/25.
//

import SwiftUI

struct TooltipHelpers {
    static let defaultConfig = TooltipConfig(maxWidth: 320)
    
    @MainActor
    static func setTooltipOnHover(
        isHovering: Bool,
        ignoreMouseEvents: Bool = false,
        tooltipShortcut: Tooltip.Shortcut = .none,
        tooltipPrompt: String?,
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
                    delayEnd: 0,
                    ignoreMouseEvents: ignoreMouseEvents
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

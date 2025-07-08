//
//  TooltipHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 7/8/25.
//

import SwiftUI

struct TooltipHelpers {
    static let defaultTruncation = TooltipViewTruncated(maxWidth: 320)
    
    @MainActor
    static func setOptionalTooltip(
        isHovering: Bool,
        ignoreMouseEvents: Bool = false,
        tooltipShortcut: Tooltip.Shortcut = .none,
        tooltipPrompt: String?,
        tooltipTruncated: TooltipViewTruncated? = nil
    ) {
        if tooltipPrompt != nil {
            if isHovering {
                TooltipManager.shared.setTooltip(
                    Tooltip(
                        prompt: tooltipPrompt!,
                        shortcut: tooltipShortcut,
                    ),
                    tooltipTruncated: tooltipTruncated,
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

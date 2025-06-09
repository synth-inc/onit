//
//  PanelStatePinnedManager+Restore.swift
//  Onit
//
//  Created by Codex on 2024-06-09.
//

import AppKit

extension PanelStatePinnedManager {
    override func resetFramesOnAppChange() {
        guard let panel = state.panel else {
            super.resetFramesOnAppChange()
            return
        }

        let panelFrame = panel.frame
        targetInitialFrames.forEach { element, initialFrame in
            var shouldRestore = true
            if let currentFrame = element.getFrame(convertedToGlobalCoordinateSpace: true) {
                let touchesPanel = currentFrame.intersects(panelFrame) || abs(currentFrame.maxX - panelFrame.minX) <= 1
                if !touchesPanel {
                    shouldRestore = false
                }
            }

            if shouldRestore {
                _ = element.setFrame(initialFrame)
            }
        }
        targetInitialFrames.removeAll()
    }
}

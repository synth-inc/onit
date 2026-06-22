//
//  PanelStatePinnedManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 12/05/2025.
//

import Defaults
import Foundation
import SwiftUI

extension PanelStatePinnedManager {

    func debouncedShowTetherWindow(activeScreen: NSScreen) {
        HintManager.shared.showHintForPinned(
            state: state,
            activeScreen: activeScreen,
            onClick: { [weak self] in
                self?.tetherHintClicked(screen: activeScreen)
            }
        )
    }

    func hideTetherWindow() {
        HintManager.shared.hideHint()
    }

    private func tetherHintClicked(screen: NSScreen) {
        // Reset frames when panel jumps between monitors to ensure windows on initial frame are properly reset
        // Only call when panel is already open to avoid expensive UI work during initial launch
        if state.panelOpened {
            resetFramesOnAppChange()
        }
        state.trackedScreen = screen
        launchPanel(for: state, createNewChat: true)
    }
}

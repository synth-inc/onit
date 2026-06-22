//
//  PanelStateUntetheredManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 13/05/2025.
//

import AppKit
import Defaults
import SwiftUI

extension PanelStateUntetheredManager {

    func debouncedShowTetherWindow(state: OnitPanelState, activeScreen: NSScreen) {
        HintManager.shared.showHintForUntethered(
            state: state,
            activeScreen: activeScreen,
            onClick: {
                PanelStateCoordinator.shared.launchPanel(for: state)
            }
        )
    }

    func hideTetherWindow() {
        HintManager.shared.hideHint()

        // Remove the tutorial
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }
}

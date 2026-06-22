//
//  PanelStateTetheredManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

@preconcurrency import ApplicationServices
import Defaults
import SwiftUI

extension PanelStateTetheredManager {

    func debouncedShowTetherWindow(
        state: OnitPanelState,
        activeWindow: AXUIElement,
        action: TrackedWindowAction
    ) {
        HintManager.shared.showHintForTethered(
            state: state,
            activeWindow: activeWindow,
            action: action,
            onClick: { [weak self] in
                guard let self = self else { return }
                PanelStateCoordinator.shared.launchPanel(for: state)
            }
        )
    }

    func hideTetherWindow() {
        HintManager.shared.hideHint()
    }
}

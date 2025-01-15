//
//  Model+ModelSelection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Foundation

extension OnitModel {
    func showModelSelectionOverlay() {
        if modelSelectionWindowController == nil {
            modelSelectionWindowController = ModelSelectionWindowController(model: self)
        } else {
            closeModelSelectionOverlay()
        }
    }

    func closeModelSelectionOverlay() {
        modelSelectionWindowController?.closeOverlay()
        modelSelectionWindowController = nil
    }

    func selectModel(_ modelItem: AIModel) {
        updatePreferences { prefs in
            prefs.model = modelItem
            prefs.mode = .remote
        }
        closeModelSelectionOverlay()
    }
}

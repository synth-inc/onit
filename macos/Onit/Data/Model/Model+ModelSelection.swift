//
//  Model+ModelSelection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Foundation
import AppKit
import SwiftUI

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

    func findView(withIdentifier identifier: String, in rootView: NSView?) -> NSView? {
        guard let rootView = rootView else { return nil }

        if rootView.accessibilityIdentifier() == identifier {
            return rootView
        }

        for subview in rootView.subviews {
            if let foundView = findView(withIdentifier: identifier, in: subview) {
                return foundView
            }
        }
        return nil
    }

    var selectedModel: Binding<SelectedModel?> {
        .init { [self] in
            if preferences.mode == .local, let localModelName = preferences.localModel {
                return .local(localModelName)
            } else if let aiModel = preferences.model {
                return .remote(aiModel)
            } else {
                return nil
            }
        } set: { [self] newValue in
            guard let newValue else { return }
            switch newValue {
            case .remote(let aiModel):
                updatePreferences { prefs in
                    prefs.model = aiModel
                    prefs.mode = .remote
                }
            case .local(let localModelName):
                updatePreferences { prefs in
                    prefs.localModel = localModelName
                    prefs.mode = .local
                }
            }
        }
    }

    var defaultRemoteModel: AIModel? {
        get {
            preferences.model
        }
        set {
            preferences.model = newValue
            Preferences.save(preferences)
        }
    }

    var defaultLocalModel: String? {
        get {
            preferences.localModel
        }
        set {
            preferences.localModel = newValue
            Preferences.save(preferences)
        }
    }
}

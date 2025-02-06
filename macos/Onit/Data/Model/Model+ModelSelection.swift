//
//  Model+ModelSelection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import AppKit
import Defaults
import Foundation
import SwiftUI

extension OnitModel {
  func showModelSelectionOverlay() {
    if modelSelectionWindowController == nil {
      modelSelectionWindowController = OverlayWindowController(
        model: self, content: ModelSelectionView())
    } else {
      closeModelSelectionOverlay()
    }
  }

  func closeModelSelectionOverlay() {
    modelSelectionWindowController?.closeOverlay()
    modelSelectionWindowController = nil
  }

  func selectModel(_ modelItem: AIModel) {
    Defaults[.remoteModel] = modelItem
    Defaults[.mode] = .remote

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
}

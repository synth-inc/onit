//
//  Model+AutoContext.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2025.
//

import AppKit
import Foundation
import SwiftUI

extension OnitModel {

  /**
     * Display the AutoContext's window
     * - parameter context: `Context` with `.auto` type
     */
  func showAutoContextWindow(context: Context) {
    if let controller = autoContextWindowControllers[context] {
      controller.bringToFront()
    } else {
      guard let controller = AutoContextWindowController(model: self, context: context) else {
        /** Skip when context isn't `.auto` */
        return
      }

      autoContextWindowControllers[context] = controller
      controller.showWindow()
    }
  }

  /**
     * Close the AutoContext's window corresponding to `context`
     * - parameter context: `Context` with `.auto` type
     */
  func closeAutoContextWindow(context: Context) {
    autoContextWindowControllers[context]?.closeWindow()
    autoContextWindowControllers.removeValue(forKey: context)
  }
}

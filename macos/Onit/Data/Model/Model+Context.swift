//
//  Model+Context.swift
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
    func showContextWindow(context: Context) {
        if let controller = contextWindowControllers[context] {
            controller.bringToFront()
        } else {
            guard let controller = ContextWindowController(model: self, context: context) else {
                /** Skip when context isn't `.auto` */
                return
            }

            contextWindowControllers[context] = controller
            controller.showWindow()
        }
    }

    /**
     * Close the AutoContext's window corresponding to `context`
     * - parameter context: `Context` with `.auto` type
     */
    func closeContextWindow(context: Context) {
        contextWindowControllers[context]?.closeWindow()
        contextWindowControllers.removeValue(forKey: context)
    }
}

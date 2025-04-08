//
//  ContextWindowsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import SwiftUI

@MainActor
class ContextWindowsManager {
    
    static let shared = ContextWindowsManager()
    
    // MARK: - Properties
    
    var contextWindowControllers: [Context: ContextWindowController] = [:]
    
    // MARK: - Functions
    
    /**
     * Display the AutoContext's window
     * - parameter context: `Context` with `.auto` type
     */
    func showContextWindow(windowState: OnitPanelState, context: Context) {
        if let controller = contextWindowControllers[context] {
            controller.bringToFront()
        } else {
            guard let controller = ContextWindowController(windowState: windowState, context: context) else {
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

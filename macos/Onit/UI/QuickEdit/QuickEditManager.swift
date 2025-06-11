//
//  QuickEditManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import Foundation

@MainActor
class QuickEditManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = QuickEditManager()
    
    // MARK: - Properties
    
    private let windowController = QuickEditWindowController()
    
    // MARK: - Private initializer
    
    private init() {}
    
    // MARK: - Functions
    
    func show() {
        windowController.show()
    }
    
    func hide() {
        windowController.hide()
    }
} 

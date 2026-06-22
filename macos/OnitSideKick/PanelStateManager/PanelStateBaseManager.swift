//
//  PanelStateBaseManager.swift
//  Onit
//
//  Created by Kévin Naudin on 07/05/2025.
//

import Defaults
import Foundation
import SwiftUI

@MainActor
class PanelStateBaseManager: PanelStateManagerLogic {

    // MARK: - Properties

    let defaultState: OnitPanelState = {
        let state = OnitPanelState()
        state.defaultEnvironmentSource = "PanelStateBaseManager"
        return state
    }()
    let animationDuration: TimeInterval = 0.2

    @Published var state: OnitPanelState

    var isPanelMovable: Bool { true }
    var states: [OnitPanelState]
    var targetInitialFrames: [AXUIElement: CGRect] = [:]

    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)

    // MARK: - Initializer

    init() {
        state = defaultState
        states = []
    }
    
    // MARK: - Functions
    
    func start() {
        // Implemented by children
    }
    
    func stop() {
        if AccessibilityPermissionManager.shared.accessibilityPermissionStatus == .granted {
            resetFramesOnAppChange()
        }
        closePanels()
        for state in states {
            state.unsubscribeAsHighlightedTextDelegate()
        }

        state = defaultState
        targetInitialFrames = [:]
    }
    
    func resetFramesOnAppChange() {
        targetInitialFrames.forEach { element, initialFrame in
            _ = element.setFrame(initialFrame)
        }
        targetInitialFrames.removeAll()
    }
    
    func getState(for windowHash: UInt) -> OnitPanelState? {
        return nil
    }
    
    func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return chats
    }
    
    func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return chats
    }
    
    func launchPanel(for state: OnitPanelState, createNewChat: Bool) {
        // Implemented by children
    }
    
    func closePanel(for state: OnitPanelState) {
        state.systemPromptState.shouldShowSelection = false
        state.systemPromptState.shouldShowSystemPrompt = false
    }

    func fetchWindowContext() {
        // Implemented by children
    }
    
    // MARK: - Private functions
    
    func buildPanelIfNeeded(for state: OnitPanelState, createNewChat: Bool) {
        if let existingPanel = state.panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            existingPanel.orderFrontRegardless()
            // Focus the text input when we're activating the panel
            state.textFocusTrigger.toggle()
            
            return
        }

        // Create a new chat when creating a new panel if the setting is enabled
        // But we don't want to clear out the context, so that autocontext still works.
        if Defaults[.createNewChatOnPanelOpen], createNewChat {
            state.newChat(clearContext: false)
        }

        state.panel = OnitRegularPanel(state: state)
    }
    
    private func closePanels() {
        // Close all panels without animations
        defaultState.panel?.hide()
        defaultState.panel = nil
        
        for state in states {
            state.panel?.hide()
            state.panel = nil
        }
    }
}

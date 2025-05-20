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
    
    let defaultState = OnitPanelState()
    let animationDuration: TimeInterval = 0.2
    
    @Published var state: OnitPanelState
    @Published var tetherButtonPanelState: OnitPanelState?
    
    var isPanelMovable: Bool { true }
    var states: [OnitPanelState]
    var tetherHintDetails: TetherHintDetails
    var targetInitialFrames: [AXUIElement: CGRect] = [:]
    
    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    // MARK: - Initializer
    
    init() {
        class CustomWindow: NSWindow {
            override var canBecomeKey: Bool { true }
        }
        let window = CustomWindow(
            contentRect: NSRect(x: 0, y: 0, width: ExternalTetheredButton.containerWidth, height: ExternalTetheredButton.containerHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        tetherHintDetails = TetherHintDetails(tetherWindow: window)
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
        hideTetherWindow()
        
        state = defaultState
        tetherButtonPanelState = nil
        targetInitialFrames = [:]
    }
    
    func hideTetherWindow() {
        tetherHintDetails.showTetherDebounceTimer = nil
        tetherButtonPanelState = nil

        tetherHintDetails.tetherWindow.orderOut(nil)
        tetherHintDetails.tetherWindow.contentView = nil
        tetherHintDetails.lastYComputed = nil
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
    
    func launchPanel(for state: OnitPanelState) {
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
    
    func buildPanelIfNeeded(for state: OnitPanelState) {
        if let existingPanel = state.panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            existingPanel.orderFrontRegardless()
            // Focus the text input when we're activating the panel
            state.textFocusTrigger.toggle()
            
            return
        }

        // Create a new chat when creating a new panel if the setting is enabled
        // But we don't want to clear out the context, so that autocontext still works.
        if Defaults[.createNewChatOnPanelOpen] {
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

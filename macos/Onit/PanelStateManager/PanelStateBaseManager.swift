//
//  PanelStateBaseManager.swift
//  Onit
//
//  Created by Kévin Naudin on 07/05/2025.
//

import Foundation
import SwiftUI

@MainActor
class PanelStateBaseManager: PanelStateManagerLogic {
    
    // MARK: - Properties
    
    let defaultState = OnitPanelState()
    
    @Published var state: OnitPanelState
    @Published var tetherButtonPanelState: OnitPanelState?
    
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
    
    func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return chats
    }
    
    func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return chats
    }
    
    // MARK: - Private functions
    
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

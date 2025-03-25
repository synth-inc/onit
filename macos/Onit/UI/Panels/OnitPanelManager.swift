//
//  OnitPanelManager.swift
//  Onit
//
//  Created by Kévin Naudin on 28/03/2025.
//

import Combine
import Defaults
import SwiftUI

@MainActor
class OnitPanelManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static var shared = OnitPanelManager()
    
    // MARK: - Properties
    
    @Published var state: OnitPanelState
    var states: [pid_t: OnitPanelState] = [:]
    
    private let defaultState = OnitPanelState(activeWindow: nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private initializer
    
    private init() {
        self.state = defaultState
    }
    
    // MARK: - Functions
    
    func updateLevelState(pid: pid_t?) {
        let pid = pid ?? 0
        
        for (key, value) in states {
            if key == pid {
                value.panel?.level = .floating
            } else if value.panel?.level == .floating {
                value.panel?.level = .normal
                value.panel?.orderBack(nil)
            }
        }
    }
    
    func setAppAsRegular(_ value: Bool) {
        closeAllPanels()
        
        if value {
            state.launchPanel()
        } else {
            state = defaultState
            state.launchPanel()
        }
    }
    
    func startObserving() {
        AccessibilityNotificationsManager.shared.$activeWindowElement
            .sink(receiveValue: activeAppObserver)
            .store(in: &cancellables)
    }
    
    func stopObserving() {
        cancellables.removeAll()
    }
    
    // MARK: - Private functions
    
    private func activeAppObserver(window: AXUIElement?) {
        guard let pid = window?.pid() else {
            state = defaultState
            return
        }
        
        if let activeState = states[pid] {
            state = activeState
        } else {
            let newState = OnitPanelState(activeWindow: window)
            states[pid] = newState
            state = newState
        }
    }
    
    private func closeAllPanels() {
        defaultState.closePanel()
        
        for (_, state) in states {
            state.closePanel()
        }
    }
}

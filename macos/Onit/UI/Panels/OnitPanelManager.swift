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
    var states: [TrackedWindow: OnitPanelState] = [:]
    
    private let defaultState = OnitPanelState(trackedWindow: nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private initializer
    
    private init() {
        self.state = defaultState
    }
    
    // MARK: - Functions
    
    func updateLevelState(elementIdentifier: TrackedWindow?) {
        if let elementIdentifier = elementIdentifier {
            for (key, value) in states {
                if key == elementIdentifier {
                    value.panel?.level = .floating
                } else if value.panel?.level == .floating {
                    value.panel?.level = .normal
                    value.panel?.orderBack(nil)
                }
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
        AccessibilityNotificationsManager.shared.windowsManager.$activeTrackedWindow
            .sink(receiveValue: activeAppObserver)
            .store(in: &cancellables)
            
        AccessibilityNotificationsManager.shared.$destroyedTrackedWindow
            .sink(receiveValue: windowDestroyedObserver)
            .store(in: &cancellables)
    }
    
    func stopObserving() {
        cancellables.removeAll()
    }
    
    // MARK: - Private functions
    
    private func activeAppObserver(trackedWindow: TrackedWindow?) {
        guard let trackedWindow = trackedWindow else {
            state = defaultState
            return
        }
        print("OnitPanelManager - activeAppObserver \(trackedWindow.hash)")
        if let (key, activeState) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == trackedWindow
        }) {
            print("OnitPanelManager - activeAppObserver Found \(key.title)")
            state = activeState
        } else {
            print("OnitPanelManager - activeAppObserver New")
            let newState = OnitPanelState(trackedWindow: trackedWindow)
            states[trackedWindow] = newState
            state = newState
        }
        print("OnitPanelManager - activeAppObserver count \(states.count)")
    }
    
    private func windowDestroyedObserver(trackedWindow: TrackedWindow?) {
        guard let trackedWindow = trackedWindow else { return }
        print("""
            OnitPanelManager - windowDestroyedObserver
            title: \(trackedWindow.title)
            hash: \(trackedWindow.hash)
            """)

        if let (key, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == trackedWindow
        }) {
            print("OnitPanelManager - windowDestroyedObserver state found \(key.title)")
            state.panel?.hide()
            state.panel = nil
            states.removeValue(forKey: trackedWindow)
        }
        
        print("OnitPanelManager  - windowDestroyedObserver count \(states.count)")
        
//        if state.activeTrackedWindow == windowIdentifier {
//            state = defaultState
//        }
    }
    
    private func closeAllPanels() {
        defaultState.closePanel()
        
        for (_, state) in states {
            state.closePanel()
        }
    }
}

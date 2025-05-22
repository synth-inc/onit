//
//  KeyboardShortcutsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

@preconcurrency import AppKit
import Defaults
import KeyboardShortcuts
import PostHog
import SwiftData

@MainActor
struct KeyboardShortcutsManager {
    
    private static var didObserveAppActiveNotifications = false
    
    static func configure() {
        registerSettingsShortcuts()
        registerSystemPromptsShortcuts()
        observeAppActiveNotificationsIfNeeded()
    }
    
    static func register(systemPrompt: SystemPrompt) {
        registerShortcut(systemPrompt: systemPrompt)
    }
    
    static func unregister(systemPrompt: SystemPrompt) {
        let name = KeyboardShortcuts.Name(systemPrompt.id)
        
        KeyboardShortcuts.reset(name)
    }
    
    static func enable(modelContainer: ModelContainer) {
        var names = KeyboardShortcuts.Name.allCases
            .filter { ![.launch, .launchWithAutoContext].contains($0) }
        
        // Remove ESC if needed for pinned mode
        let isPinned = FeatureFlagManager.shared.usePinnedMode
        let isForeground = NSApp.isActive
        let escDisabled = Defaults[.escapeShortcutDisabled]
        if isPinned {
            if !isForeground || escDisabled {
                names.removeAll { $0 == .escape }
            }
        } else {
            if escDisabled {
                names.removeAll { $0 == .escape }
            }
        }
        
        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            for systemPrompt in storedPrompts {
                names.append(KeyboardShortcuts.Name(systemPrompt.id))
            }
        } catch {
            print("Enabling keyboard shortcuts - Can't fetch local system prompts: \(error)")
        }
        KeyboardShortcuts.enable(names)
        reevaluateEscShortcut()
    }

    static func disable(modelContainer: ModelContainer) {
        var names = KeyboardShortcuts.Name.allCases
            .filter { ![.launch, .launchWithAutoContext].contains($0) }
        
        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            
            for systemPrompt in storedPrompts {
                names.append(KeyboardShortcuts.Name(systemPrompt.id))
            }
        } catch {
            print("Disabling keyboard shortcuts - Can't fetch local system prompts: \(error)")
        }
        
        KeyboardShortcuts.disable(names)
    }
    
    // MARK: - Private functions
    
    /// Registering keyboard shortcuts specified in Settings/Shortcuts
    private static func registerSettingsShortcuts() {
        
        KeyboardShortcuts.Name.allCases.forEach { name in
            KeyboardShortcuts.onKeyUp(for: name) {
                let state = PanelStateCoordinator.shared.state
                
                AnalyticsManager.shortcutPressed(for: name.rawValue, panelOpened: state.panelOpened)
                
                switch name {
                case .launch:
                    PanelStateCoordinator.shared.launchPanel()
                case .launchWithAutoContext:
                    state.addAutoContext()
                    PanelStateCoordinator.shared.launchPanel()
                case .escape:
                    if state.panel != nil {
                        if state.pendingInput != nil {
                            state.pendingInput = nil
                        } else {
                            PanelStateCoordinator.shared.closePanel()
                        }
                    }
                case .newChat:
                    state.newChat()
                case .toggleLocalMode:
                    Defaults[.mode] = Defaults[.mode] == .local ? .remote : .local
                default:
                    print("KeyboardShortcut not handled: \(name)")
                }
            }
        }
        // Since we support turning on and off shortcuts, we should disable these all after registering.
        // Then, the shortcuts that are on will be enabled when enable() is called. 
        let names = KeyboardShortcuts.Name.allCases
            .filter { ![.launch, .launchWithAutoContext].contains($0) }
        KeyboardShortcuts.disable(names)
    }
    
    /// Registering keyboard shortcuts for all stored `SystemPrompt`
    private static func registerSystemPromptsShortcuts() {
        let modelContainer = SwiftDataContainer.appContainer
        
        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            
            for systemPrompt in storedPrompts {
                registerShortcut(systemPrompt: systemPrompt)
            }
        } catch {
            print("Registering systemPrompts - Can't fetch local system prompts: \(error)")
        }
    }
    
    /// Registering keyboard shortcut for a specific `SystemPrompt`
    /// - parameter systemPrompt: The system prompt
    private static func registerShortcut(systemPrompt: SystemPrompt) {
        let name = KeyboardShortcuts.Name(systemPrompt.id)
        
        KeyboardShortcuts.onKeyUp(for: name) {
            PanelStateCoordinator.shared.state.systemPromptId = systemPrompt.id
        }
    }
    
    private static func observeAppActiveNotificationsIfNeeded() {
        guard !didObserveAppActiveNotifications else { return }
        didObserveAppActiveNotifications = true
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { notification in
            DispatchQueue.main.async {
                reevaluateEscShortcut()
            }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { notification in
            DispatchQueue.main.async {
                reevaluateEscShortcut()
            }
        }
    }
    
    private static func reevaluateEscShortcut() {
        let isPinned = FeatureFlagManager.shared.usePinnedMode
        let isForeground = NSApp.isActive
        let escDisabled = Defaults[.escapeShortcutDisabled]
        if isPinned {
            if isForeground && !escDisabled {
                KeyboardShortcuts.enable(.escape)
            } else {
                KeyboardShortcuts.disable(.escape)
            }
        } else {
            // In non-pinned mode, follow the normal toggle
            if !escDisabled {
                KeyboardShortcuts.enable(.escape)
            } else {
                KeyboardShortcuts.disable(.escape)
            }
        }
    }
}

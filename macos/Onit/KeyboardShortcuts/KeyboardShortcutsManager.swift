//
//  KeyboardShortcutsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

import Defaults
import KeyboardShortcuts
import PostHog
import SwiftData

@MainActor
struct KeyboardShortcutsManager {
    
    static func configure(model: OnitModel) {
        registerSettingsShortcuts(model: model)
        registerSystemPromptsShortcuts(modelContainer: model.container)
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
        
        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            
            for systemPrompt in storedPrompts {
                names.append(KeyboardShortcuts.Name(systemPrompt.id))
            }
        } catch {
            print("Enabling keyboard shortcuts - Can't fetch local system prompts: \(error)")
        }
        
        KeyboardShortcuts.enable(names)
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
    /// - parameter model: Instance of `OnitModel`
    private static func registerSettingsShortcuts(model: OnitModel) {
        KeyboardShortcuts.Name.allCases.forEach { name in
            KeyboardShortcuts.onKeyUp(for: name) {
                switch name {
                case .launch:
                    let eventProperties: [String: Any] = [
                        "app_hidden": model.panel == nil,
                        "highlight_hint_visible": HighlightHintWindowController.shared.isVisible(),
                        "highlight_hint_mode": FeatureFlagManager.shared.highlightHintMode,
                    ]
                    PostHogSDK.shared.capture("shortcut_launch", properties: eventProperties)

                    model.launchShortcutAction()
                case .launchWithAutoContext:
                    let eventProperties: [String: Any] = [
                        "app_hidden": model.panel == nil
                    ]
                    PostHogSDK.shared.capture(
                        "shortcut_launch_with_auto_context", properties: eventProperties)
                    model.addAutoContext()
                    model.launchPanel()
                case .escape:
                    model.escapeAction()
                case .newChat:
                    model.newChat()
                case .resizeWindow:
                    model.resizeWindow()
                case .toggleLocalMode:
                    model.toggleLocalVsRemoteShortcutAction()
                default:
                    print("KeyboardShortcut not handled: \(name)")
                }
            }
        }
    }
    
    /// Registering keyboard shorcuts for all stored `SystemPrompt`
    /// - parameter modelContainer: ModelContainer used to query SwiftData
    private static func registerSystemPromptsShortcuts(modelContainer: ModelContainer) {
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
            Defaults[.systemPromptId] = systemPrompt.id
        }
    }
}

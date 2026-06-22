//
//  KeyboardShortcutsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

@preconcurrency import AppKit
import Combine
import Defaults
import KeyboardShortcuts
import PostHog
import SwiftData

@MainActor
class KeyboardShortcutsManager {

    private static var panelShortcutsEnabled = true

    // Dev build coexistence state
    private static var devBuildCancellables = Set<AnyCancellable>()
    private static var isDisabledForDevBuild = false

    private init() {}

    // Shortcuts that should always be active when sidebar is enabled (to open/reopen the panel)
    static let panelLaunchShortcuts: [KeyboardShortcuts.Name] = [
        .launch,
        .launchWithAutoContext
    ]

    // Shortcuts that should only be active when the panel has focus
    static let panelActiveShortcuts: [KeyboardShortcuts.Name] = [
        .newChat,
        .toggleLocalMode,
        .addForegroundWindowToContext
    ]

    static let panelShortcuts: [KeyboardShortcuts.Name] = panelLaunchShortcuts + panelActiveShortcuts

    static var capsLockModifierShortcuts: [KeyboardShortcuts.Name] {
        get {
            return Defaults[.capsLockModifierShortcuts].compactMap { nameString in
                KeyboardShortcuts.Name.allCases.first { $0.rawValue == nameString }
            }
        }
        set {
            Defaults[.capsLockModifierShortcuts] = newValue.map { $0.rawValue }
        }
    }

    static func configure() {
        registerRemappedKeyShortcuts()
        registerPanelShortcuts()

        KeyboardShortcuts.enable([.remappedKeyConsumer, .remappedKeyConsumerShifted])

        KeyboardShortcuts.disable(capsLockModifierShortcuts)

        // Apply or remove HID remappings based on what features currently need.
        // This also cleans up stale mappings from a previous crash/force-quit.
        if KeystrokeNotificationManager.shared.isHIDRemappingNeededByAnyFeature() {
            KeystrokeNotificationManager.shared.applyHIDRemapping(context: "Startup")
        } else {
            KeystrokeNotificationManager.shared.removeHIDRemapping()
        }
    }

    static func setShortcut(name: KeyboardShortcuts.Name, shortcut: KeyboardShortcuts.Shortcut, usesCapsLockModifier: Bool) {
        var currentShortcuts = Self.capsLockModifierShortcuts

        if (usesCapsLockModifier) {
            // Add the shortcut to the list of capsLockShortcuts if not already present
            if !currentShortcuts.contains(name) {
                currentShortcuts.append(name)
            }
        } else {
            // Remove the shortcut from the list of capsLockShortcuts if present
            currentShortcuts.removeAll { $0 == name }
        }

        // Update the persistent storage
        Self.capsLockModifierShortcuts = currentShortcuts
        KeyboardShortcuts.setShortcut(shortcut, for: name)

        // Re-evaluate HID remapping: apply if CapsLock is now needed, remove if not
        if KeystrokeNotificationManager.shared.isHIDRemappingNeededByAnyFeature() {
            KeystrokeNotificationManager.shared.applyHIDRemapping(context: "CapsLockModifierShortcut")
        } else {
            KeystrokeNotificationManager.shared.removeHIDRemappingIfNotNeeded()
        }
    }

    static func enablePanelShortcuts(modelContainer: ModelContainer) {
        panelShortcutsEnabled = true
        var names = Self.panelShortcuts

        let modeToggleDisabled = Defaults[.modeToggleShortcutDisabled]
        if modeToggleDisabled {
            names.removeAll { $0 == .toggleLocalMode }
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
    }

    static func disablePanelShortcuts(modelContainer: ModelContainer) {
        panelShortcutsEnabled = false
        var names = Self.panelShortcuts
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

    /// Enable only the panel-active shortcuts (when panel gains focus).
    /// Launch shortcuts remain managed by enableSidebarCancellable.
    static func enablePanelActiveShortcuts(modelContainer: ModelContainer) {
        var names = Self.panelActiveShortcuts

        let modeToggleDisabled = Defaults[.modeToggleShortcutDisabled]
        if modeToggleDisabled {
            names.removeAll { $0 == .toggleLocalMode }
        }

        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            for systemPrompt in storedPrompts {
                names.append(KeyboardShortcuts.Name(systemPrompt.id))
            }
        } catch {
            print("Enabling panel active shortcuts - Can't fetch local system prompts: \(error)")
        }
        KeyboardShortcuts.enable(names)
    }

    /// Disable only the panel-active shortcuts (when panel loses focus).
    /// Launch shortcuts remain enabled to allow reopening the panel.
    static func disablePanelActiveShortcuts(modelContainer: ModelContainer) {
        var names = Self.panelActiveShortcuts
        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            for systemPrompt in storedPrompts {
                names.append(KeyboardShortcuts.Name(systemPrompt.id))
            }
        } catch {
            print("Disabling panel active shortcuts - Can't fetch local system prompts: \(error)")
        }
        KeyboardShortcuts.disable(names)
    }

    static func resetKeyboardShortcut(
        for shortcutName: KeyboardShortcuts.Name,
        to previousShortcut: KeyboardShortcuts.Shortcut? = nil
    ) {
        if let previousShortcut = previousShortcut {
            KeyboardShortcuts.setShortcut(previousShortcut, for: shortcutName)
        } else {
            KeyboardShortcuts.reset(shortcutName)
        }
    }

    // MARK: - Registration

    static func register(systemPrompt: SystemPrompt) {
        registerShortcut(systemPrompt: systemPrompt)
    }

    static func unregister(systemPrompt: SystemPrompt) {
        let name = KeyboardShortcuts.Name(systemPrompt.id)

        KeyboardShortcuts.reset(name)
    }

    // MARK: - Caps Lock State

    private static var isCapsLockPressed: Bool = false

    private static func onCapsDown() {
        guard !isCapsLockPressed else { return }
        isCapsLockPressed = true

        executeCapsLockTappedShortcutsIfNeeded()
    }

    private static func onCapsUp() {
        guard isCapsLockPressed else { return }
        isCapsLockPressed = false
    }

    private static func registerRemappedKeyShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .remappedKeyConsumer) {
            Task { @MainActor in
                Self.onCapsDown()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .remappedKeyConsumer) {
            Task { @MainActor in
                Self.onCapsUp()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .remappedKeyConsumerShifted) {
            Task { @MainActor in
                CapsLockToggleManager.toggle()
            }
        }
    }

    private static func registerPanelShortcuts() {
        panelShortcuts.forEach { name in
            KeyboardShortcuts.onKeyUp(for: name) {
                Task { @MainActor in
                    executeShortcut(name: name)
                }
            }
        }
        registerSystemPromptsShortcuts()

        // Since we support turning on and off shortcuts, we should disable these all after registering.
        // Then, the shortcuts that are on will be enabled when enable() is called.
        if !Defaults[.enableSidebar] {
            KeyboardShortcuts.disable(panelShortcuts)
            panelShortcutsEnabled = false
        }
    }

    /// Registering keyboard shortcuts for all stored `SystemPrompt`
    static func registerSystemPromptsShortcuts() {
        let modelContainer = SwiftDataContainer.appContainer

        do {
            let storedPrompts = try modelContainer.mainContext.fetch(FetchDescriptor<SystemPrompt>())
            for systemPrompt in storedPrompts {
                registerShortcut(systemPrompt: systemPrompt)
                if !Defaults[.enableSidebar] {
                    let name = KeyboardShortcuts.Name(systemPrompt.id)
                    KeyboardShortcuts.disable([name])
                }
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
            Task { @MainActor in
                PanelStateCoordinator.shared.state.systemPromptId = systemPrompt.id
            }
        }
    }

    // MARK: - Execution

    private static func executeShortcut(name: KeyboardShortcuts.Name) {
        let state = PanelStateCoordinator.shared.state
        AnalyticsManager.shortcutPressed(for: name.rawValue, panelOpened: state.panelOpened)

        switch name {
        case .launch:
            PanelStateCoordinator.shared.launchPanel()
        case .launchWithAutoContext:
            state.addAutoContext()
            PanelStateCoordinator.shared.launchPanel()
        case .newChat:
            state.newChat()
        case .toggleLocalMode:
            Defaults[.mode] = Defaults[.mode] == .local ? .remote : .local
        case .addForegroundWindowToContext:
            if let foregroundWindow = state.foregroundWindow {
                state.addWindowToContext(window: foregroundWindow.element)
            }
        default:
            print("KeyboardShortcut not handled: \(name)")
        }
    }

    static func executeCapsLockTappedShortcutsIfNeeded() {
        let eventMods = KeystrokeNotificationManager.shared.getCurrentModifierStates()

        for name in KeyboardShortcuts.Name.allCases {
            if let shortcut = KeyboardShortcuts.getShortcut(for: name),
               shortcut.key == .capsLock {
                let shortcutMods = shortcut.modifiers
                let matches = [
                    (eventMods.command, shortcutMods.contains(.command)),
                    (eventMods.control, shortcutMods.contains(.control)),
                    (eventMods.shift, shortcutMods.contains(.shift)),
                    (eventMods.option, shortcutMods.contains(.option))
                ].allSatisfy { $0.0 == $0.1 }
                if !matches { continue }
                executeShortcut(name: name)
            }
        }
    }

    // MARK: - Dev Build Coexistence

    /// Start observing dev build detection service (Release builds only)
    static func observeDevBuildDetection() {
        #if !DEBUG
        DevBuildDetectionService.shared.$isDevBuildRunning
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { isDevBuildRunning in
                if isDevBuildRunning {
                    disableAllForDevBuildCoexistence()
                } else {
                    restoreAfterDevBuildCoexistence()
                }
            }
            .store(in: &devBuildCancellables)
        #endif
    }

    /// Disable all shortcuts when dev build is running
    private static func disableAllForDevBuildCoexistence() {
        guard !isDisabledForDevBuild else { return }
        isDisabledForDevBuild = true

        // Disable all registered shortcuts
        var allShortcuts: [KeyboardShortcuts.Name] = []
        allShortcuts.append(contentsOf: panelShortcuts)
        allShortcuts.append(.remappedKeyConsumer)
        allShortcuts.append(.remappedKeyConsumerShifted)
        KeyboardShortcuts.disable(allShortcuts)
    }

    /// Restore shortcuts when dev build is no longer running
    private static func restoreAfterDevBuildCoexistence() {
        guard isDisabledForDevBuild else { return }
        isDisabledForDevBuild = false

        // Re-enable shortcuts based on their previous state
        // remapped key consumers are always enabled
        KeyboardShortcuts.enable([.remappedKeyConsumer, .remappedKeyConsumerShifted])

        if panelShortcutsEnabled {
            KeyboardShortcuts.enable(panelShortcuts)
        }
    }
}

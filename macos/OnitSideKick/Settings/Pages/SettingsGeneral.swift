//
//  SettingsGeneral.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import KeyboardShortcuts
import PostHog
import ServiceManagement
import SwiftUI
import Defaults

struct SettingsGeneral: View {
    // MARK: - Defaults
    
    @Default(.hideDockIcon) private var hideDockIcon
    @Default(.alwaysHideHint) private var alwaysHideHint
    @Default(.appAppearance) private var appAppearance
    
    // MARK: - States
    
    @State var previousLaunchShortcut: KeyboardShortcuts.Shortcut? = KeyboardShortcuts.Name.launch.shortcut
    
    @State var isLaunchAtStartupEnabled: Bool = SMAppService.mainApp.status == .enabled
    @State var isUpdatingLaunchAtStartup: Bool = false
    @State var launchAtStartupErrorMessage: String? = nil

    @State var autoInstallUpdates: Bool = AppState.shared.updater.updater.automaticallyDownloadsUpdates
    
    @State var isAnalyticsEnabled: Bool = PostHogSDK.shared.isOptOut() == false
    @State var isUpdatingAnalyticsEnabled: Bool = false
    @State var analyticsEnabledErrorMessage: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        generalSection
    }

    // MARK: - Child Components: General Section

    private var generalSection: some View {
        SettingsPageSection(title: .init(text: String.localized("General", table: "Settings"))) {
            hideDockIconToggle
            DividerHorizontal()
            alwaysHideHintToggle
            DividerHorizontal()
            launchOnStartup
            DividerHorizontal()
            autoInstallUpdatesToggle
            DividerHorizontal()
            analytics
            DividerHorizontal()
            appearanceSection
        }
    }
    
    private var hideDockIconToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Hide dock icon", table: "Settings"),
                subtitle: String.localized("Show only the menu bar icon.", table: "Settings")
            ),
            isOn: self.$hideDockIcon
        )
        .onChange(of: hideDockIcon, initial: false) { _, _ in
            AppDelegate.configureDockIconVisibility()
        }
    }
    
    private var alwaysHideHintToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Always hide hint", table: "Settings"),
                subtitle: String.localized("Permanently hide the hint button that shows on the right side of your screen. Important alerts will still be shown.", table: "Settings"),
            ),
            isOn: $alwaysHideHint
        )
    }
    
    private var launchOnStartup: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = launchAtStartupErrorMessage {
                errorMessageView(errorMessage)
            }

            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Launch automatically at login", table: "Settings"),
                    subtitle: String.localized("Open Onit automatically when you log into your computer.", table: "Settings"),
                ),
                isOn: $isLaunchAtStartupEnabled
            )
            .disabled(isUpdatingLaunchAtStartup)
            .onChange(of: isLaunchAtStartupEnabled, initial: false) { old, new in
                guard !isUpdatingLaunchAtStartup else { return }

                toggleLaunchAtStartup(
                    shouldLaunchAtStartup: new,
                    originalValue: old
                )
            }
        }
    }
    
    private var autoInstallUpdatesToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Automatically install updates", table: "Settings"),
                subtitle: String.localized("Install updates in the background and apply them on next launch.", table: "Settings")
            ),
            isOn: $autoInstallUpdates
        )
        .onChange(of: autoInstallUpdates, initial: false) { _, new in
            AppState.shared.updater.updater.automaticallyDownloadsUpdates = new
            AnalyticsManager.Settings.autoInstallUpdatesToggled(enabled: new)
        }
    }

    private var analytics: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = analyticsEnabledErrorMessage {
                errorMessageView(errorMessage)
            }

            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Enable anonymous analytics", table: "Settings"),
                    subtitle: String.localized("Help us improve your experience! We collect fully anonymized data to enhance performance and fix issues faster.", table: "Settings"),
                ),
                isOn: $isAnalyticsEnabled
            )
            .disabled(isUpdatingAnalyticsEnabled)
            .onChange(of: isAnalyticsEnabled, initial: false) { old, new in
                guard !isUpdatingAnalyticsEnabled else { return }

                toggleAnalyticsOptOut(
                    shouldOptIn: new,
                    originalValue: old
                )
            }
        }
    }

    private var appearanceSection: some View {
        SettingsPageSubsection(
            header: .init(title: String.localized("Appearance", table: "Settings")),
            dropdown: .init(
                placeholder: String.localized("Select an appearance", table: "Settings"),
                options: AppAppearance.allCases.map { appearanceOption in
                        .init(
                            id: UUID(),
                            name: appearanceOption.displayName,
                            isSelected: appearanceOption == appAppearance,
                            action: {
                                AppAppearance.set(appearanceOption)
                            }
                        )
                }
            )
        )
    }

    // MARK: - Child Components: Shared
    
    private func errorMessageView(_ errorMessage: String) -> some View {
        Text(errorMessage)
            .styleText(
                size: 13,
                weight: .regular,
                color: Color.red500
            )
    }

    // MARK: - Private Functions
    
    private func toggleLaunchAtStartup(
        shouldLaunchAtStartup: Bool,
        originalValue: Bool
    ) {
        isUpdatingLaunchAtStartup = true
        defer { isUpdatingLaunchAtStartup = false }
        
        launchAtStartupErrorMessage = nil
        
        do {
            if shouldLaunchAtStartup {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            
            isLaunchAtStartupEnabled = shouldLaunchAtStartup
        } catch {
            print("Error : \(error)")
         
            isLaunchAtStartupEnabled = originalValue
            launchAtStartupErrorMessage = error.localizedDescription
        }
    }
    
    private func toggleAnalyticsOptOut(
        shouldOptIn: Bool,
        originalValue: Bool
    ) {
        isUpdatingAnalyticsEnabled = true
        defer { isUpdatingAnalyticsEnabled = false }
        
        analyticsEnabledErrorMessage = nil
        
        if shouldOptIn {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
        
        let isNowOptedIn = PostHogSDK.shared.isOptOut() == false
        let failedToUpdate = isNowOptedIn != shouldOptIn
        
        if failedToUpdate {
            isAnalyticsEnabled = originalValue
            analyticsEnabledErrorMessage = String.localized("Update failed. Please try again.", table: "Settings")
        } else {
            isAnalyticsEnabled = shouldOptIn
        }
    }
}

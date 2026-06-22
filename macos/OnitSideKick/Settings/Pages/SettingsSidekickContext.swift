//
//  SettingsSidekickContext.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import AppKit
import Defaults
import SwiftUI

struct SettingsSidekickContext: View {
    // MARK: - Defaults

    @Default(.autoContextFromHighlights) private var autoContextFromHighlights
    @Default(.autoContextFromCurrentWindow) private var autoContextFromCurrentWindow

    // MARK: - Observed Objects

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    // MARK: - Computed Properties

    private var autoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    // MARK: - Body

    var body: some View {
        autoContextHeaderView
        optionsSection
    }

    // MARK: - Child Components: Auto Context Header View

    private var autoContextHeaderView: some View {
        SettingsPageSection {
            SettingsPageSubsection(
                vertical: .init(spacing: 8),
                header: .init(
                    title: String.localized("AutoContext", table: "Sidekick"),
                    subtitle: String.localized("With AutoContext, Onit can load context directly from your computer using Apple's screen reader APIs. AutoContext spares you the hassle of manually uploading files or copy/pasting. Data loaded with AutoContext is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.", table: "Sidekick")
                )
            ) {
                if let demoUrl = featureFlagsManager.autocontextDemoVideoUrl {
                    TextButton(
                        text: String.localized("Watch the demo", table: "Sidekick"),
                        iconConfig: .init(
                            leftIconName: "play.circle.fill"
                        ),
                        colorConfig: .init(
                            text: Color.white,
                            background: Color.blue
                        ),
                        sizeConfig: .init(
                            text: 13,
                            height: 32
                        )
                    ) {
                        NSWorkspace.shared.open(URL(string: demoUrl)!)
                    }
                }
            }
        }
    }
    
    // MARK: - Child Components: Options Section
    
    private var optionsSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Options", table: "Sidekick"))) {
            accessibilityToggle

            if autoContextEnabled {
                DividerHorizontal()
                highlightedTextToggle
                DividerHorizontal()
                currentWindowToggle
            }
        }
    }

    private var accessibilityToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Accessibility enabled", table: "Sidekick"),
                subtitle: String.localized("Required for automatic context loading, text insertion, window resizing, and many other Onit features.", table: "Sidekick")
            ),
            isOn: Binding(
                get: { autoContextEnabled },
                set: { _ in
                    AccessibilityPermissionManager.shared.requestPermission()
                }
            )
        )
    }

    private var highlightedTextToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Highlighted Text", table: "Sidekick"),
                subtitle: String.localized("Automatically loads highlighted text as content. When enabled, Onit will read highlighted text from any application, and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.", table: "Sidekick")
            ),
            isOn: self.$autoContextFromHighlights
        )
    }

    private var currentWindowToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Current Window (Experimental)", table: "Sidekick"),
                subtitle: String.localized("Loads context from the active window. When enabled, Onit adds a shortcut that, when triggered, will read the text from the foregrounded application and add it as context to your conversation. Note: this feature may not work in every application.", table: "Sidekick")
            ),
            isOn: self.$autoContextFromCurrentWindow
        )
    }
}

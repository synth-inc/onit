//
//  SettingsSetup.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import Defaults
import SwiftUI

struct SettingsSetup: View {
    // MARK: - Defaults
    
    @Default(.currentOnboardingStep) private var currentOnboardingStep

    // MARK: - States

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var screenRecordingPermissionManager = ScreenRecordingPermissionManager.shared
    
    // MARK: - Private Variables
    
    let onboardingWindowManager = OnboardingWindowManager.shared
    
    /// Onboarding is complete only if:
    /// - The main onboarding flow reached .complete
    /// - AND all enabled features have their specific steps completed
    private var completedOnboarding: Bool {
        return OnboardingStep.isOnboardingComplete
    }
    
    private var grantedAccessibility: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var grantedScreenshotPermission: Bool {
        return self.screenRecordingPermissionManager.isScreenRecordingEnabled
    }
    
    private var skipOnboardingButton: SectionButton {
        return SectionButton(
            text: String.localized("Skip", table: "Settings"),
            color: Color.S_4,
            disabled: false
        ) {
            self.currentOnboardingStep = .complete
        }
    }

    private var continueOnboardingButton: SectionButton {
        return SectionButton(
            text: self.completedOnboarding ? String.localized("Completed", table: "Settings") : String.localized("Continue →", table: "Settings"),
            color: self.completedOnboarding ? Color.S_3 : Color.blue,
            disabled: self.completedOnboarding
        ) {
            self.launchOnboarding()
        }
    }

    /// Launches onboarding at the appropriate step based on current state
    private func launchOnboarding() {
        guard let firstValidStep = OnboardingStep.steps.first,
              firstValidStep != .complete
        else {
            return
        }
        
        onboardingWindowManager.showWindow(startingAt: firstValidStep)
    }
    
    // MARK: - Body
    
    var body: some View {
        SettingsTitleView(
            text: String.localized("Complete the setup list to ensure Onit works seamlessly.", table: "Settings")
        )

        requiredSection
    }

    // MARK: - Child Components: Required Section

    private var requiredSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Required", table: "Settings"))) {
            section(
                title: String.localized("Complete Onboarding", table: "Settings"),
                caption: String.localized("A quick guide to help you get started.", table: "Settings"),
                status: SectionStatus(
                    icon: self.completedOnboarding ? .checkCircle : .warningCircle,
                    color: self.completedOnboarding ? Color.lime400 : Color.red500
                ),
                buttons: self.completedOnboarding ?
                    [self.continueOnboardingButton] :
                    [self.skipOnboardingButton, self.continueOnboardingButton]
            )

            DividerHorizontal()

            section(
                title: String.localized("Accessibility Permissions", table: "Settings"),
                caption: String.localized("This lets Onit load context and give relevant suggestions.", table: "Settings"),
                status: SectionStatus(
                    icon: self.grantedAccessibility ? .checkCircle : .warningCircle,
                    color: self.grantedAccessibility ? Color.lime400 : Color.red500
                ),
                buttons: [SectionButton(
                    text: self.grantedAccessibility ? String.localized("Granted", table: "Settings") : String.localized("Grant Access", table: "Settings"),
                    color: self.grantedAccessibility ? Color.S_3 : Color.blue,
                    disabled: self.grantedAccessibility
                ) {
                    accessibilityPermissionManager.requestPermission()
                }]
            )

            DividerHorizontal()

            section(
                title: String.localized("Screenshots Permissions", table: "Settings"),
                caption: String.localized("Get better & more relevant suggestions (you'll need to quit & reopen Onit to activate permission)", table: "Settings"),
                status: SectionStatus(
                    icon: self.grantedScreenshotPermission ? .checkCircle : .warningCircle,
                    color: self.grantedScreenshotPermission ? Color.lime400 : Color.red500
                ),
                buttons: [SectionButton(
                    text: self.grantedScreenshotPermission ? String.localized("Granted", table: "Settings") : String.localized("Grant Access", table: "Settings"),
                    color: self.grantedScreenshotPermission ? Color.S_3 : Color.blue,
                    disabled: self.grantedScreenshotPermission
                ) {
                    Task {
                        _ = await self.screenRecordingPermissionManager.requestScreenRecordingPermission()
                    }
                }]
            )
        }
    }

    // MARK: - Child Components: Section
    
    struct SectionStatus {
        let icon: ImageResource
        let color: Color
    }
    
    struct SectionButton: Equatable {
        let id: UUID
        let text: String
        let color: Color
        let disabled: Bool
        let action: () -> Void
        
        init(
            text: String,
            color: Color,
            disabled: Bool,
            action: @escaping () -> Void
        ) {
            self.id = UUID()
            self.text = text
            self.color = color
            self.disabled = disabled
            self.action = action
        }
        
        static func == (lhs: SectionButton, rhs: SectionButton) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    private func section(
        title: String,
        caption: String,
        status: SectionStatus? = nil,
        buttons: [SectionButton]
    ) -> some View {
        SettingsPageSubsection(
            horizontal: .init(
                alignment: .top,
                spacing: 8
            ),
            header: .init(
                title: title,
                subtitle: caption
            ),
            imageResource: status != nil ? .init(
                resource: status!.icon,
                color: status!.color
            ) : nil
        ) {
            ForEach(buttons, id: \.id) { button in
                SimpleButton(
                    disabled: button.disabled,
                    text: button.text,
                    action: button.action,
                    background: button.color
                )
            }
        }
    }
}

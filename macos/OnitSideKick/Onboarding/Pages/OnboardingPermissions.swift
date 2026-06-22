//
//  OnboardingPermissions.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingPermissions: View {
    // MARK: - Defaults

    @Default(.currentOnboardingStep) var currentStep

    // MARK: - States

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var screenRecordingPermissionManager = ScreenRecordingPermissionManager.shared

    @State private var hasRepositionedWindowsSideBySide: Bool = false

    @State private var shouldShowScreenshotPermissionSheet: Bool = false
    
    // MARK: - Private Variables: Constants
    
    private var requiredCaptionText: String { String.localized("Required", table: "Onboarding") }

    // MARK: - Private Variables: Permissions


    private var grantedAccessibility: Bool {
        return accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    private var grantedScreenRecording: Bool {
        return screenRecordingPermissionManager.isScreenRecordingEnabled
    }

    private var allAccessGranted: Bool {
        return grantedAccessibility
    }

    // MARK: - Body

    var body: some View {
        OnboardingPage(
            footerConfig: .init(
                nextButtonDisabled: Binding(
                    get: { !allAccessGranted },
                    set: { _ in }
                )
            ),
            bodyContent: {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        accessibilityPermissionRow
                        divider
                        screenshotPermissionRow
                    }
                    .padding(.top, 47)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 26)
                    .frame(width: 629)
                }
            },
            footerContent: {
                Spacer()
            }
        )
        .sheet(isPresented: $shouldShowScreenshotPermissionSheet) {
            ScreenshotPermissionExampleSheet(
                shouldShow: $shouldShowScreenshotPermissionSheet
            )
        }
        .onChange(of: grantedAccessibility) { _, isGranted in
            // Only reposition if accessibility was just granted and not all permissions are done yet
            // This prevents repositioning on app restart when permissions are already complete
            if isGranted && !hasRepositionedWindowsSideBySide && !allAccessGranted {
                // Now that accessibility is granted, we can reposition Settings
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    repositionWindowsSideBySide()
                    hasRepositionedWindowsSideBySide = true
                }
            }
        }
    }
    
    // MARK: - Child Components: Sections
    
    private var divider: some View {
        DividerHorizontal(foregroundColor: Color.T_9)
    }

    private var accessibilityPermissionRow: some View {
        PermissionRow(
            icon: .settingsAccessibility,
            title: String.localized("Accessibility", table: "Onboarding"),
            caption: requiredCaptionText,
            isGranted: grantedAccessibility,
            buttonText: grantedAccessibility ? String.localized("Granted", table: "Onboarding") : String.localized("Grant access", table: "Onboarding"),
        ) {
            bulletPointTextView(String.localized("This lets Onit load context and give relevant suggestions.", table: "Onboarding"))
        } buttonAction: {
            if !grantedAccessibility {
                accessibilityPermissionManager.requestPermission()
            }
        }
    }
    
    private var screenshotPermissionRow: some View {
        PermissionRow(
            icon: .settingsScreenshots,
            title: String.localized("Screenshots", table: "Onboarding"),
            caption: String.localized("Recommended", table: "Onboarding"),
            isGranted: grantedScreenRecording,
            buttonText: grantedScreenRecording ? String.localized("Granted", table: "Onboarding") : String.localized("Grant access", table: "Onboarding"),
        ) {
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "circle.fill")
                    .padding(.top, 7)
                    .styleText(
                        size: 3,
                        weight: .regular,
                        color: Color.T_1
                    )
                
                Button {
                    shouldShowScreenshotPermissionSheet = true
                } label: {
                    Text(String.localized("This helps Onit find empty space so it doesn't cover what you're working on. (", table: "Onboarding"))
                    + Text(String.localized("See how", table: "Onboarding"))
                        .underline()
                        .foregroundColor(Color.S_0)
                    + Text(String.localized(")", table: "Onboarding"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            bulletPointTextView(String.localized("Screenshots never leave your Mac — they're used once and deleted instantly.", table: "Onboarding"))
        } buttonAction: {
            if !grantedScreenRecording {
                Task {
                    _ = await screenRecordingPermissionManager.requestScreenRecordingPermission()
                }
            }
        }
    }
    
    // MARK: - Child Components: Bullet Point Text View
    
    private func bulletPointTextView(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "circle.fill")
                .padding(.top, 7)
                .styleText(
                    size: 3,
                    weight: .regular,
                    color: Color.T_1
                )
            
            Text(text)
                .styleText(
                    weight: .regular,
                    color: Color.T_1
                )
        }
    }
    
    // MARK: - Child Components: Permission Row

    private struct PermissionRow<BulletPoints: View>: View {
        let icon: ImageResource
        let title: String
        var caption: String? = nil
        let isGranted: Bool
        let buttonText: String
        @ViewBuilder let bulletPoints: BulletPoints
        let buttonAction: () -> Void

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(icon)
                            .resizable()
                            .frame(width: 20)
                            .frame(height: 20)

                        Text(title)
                            .styleText(
                                size: 15,
                                weight: .regular
                            )
                            .fixedSize(horizontal: false, vertical: true)

                        if let caption = caption {
                            Text(caption)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 5)
                                .styleText(
                                    size: 13,
                                    weight: .regular,
                                    color: Color.T_1
                                )
                                .background(Color.T_8)
                                .cornerRadius(6)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        bulletPoints
                    }
                    .styleText(
                        size: 14,
                        weight: .regular,
                        color: Color.T_1
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PulsingPermissionButton(
                    text: buttonText,
                    isGranted: isGranted,
                    action: buttonAction
                )
            }
        }
    }

    // MARK: - Child Components: Pulsing Permission Button

    private struct PulsingPermissionButton: View {
        let text: String
        let isGranted: Bool
        let action: () -> Void

        var body: some View {
            TextButton(
                text: text,
                iconConfig: .init(
                    rightIconName: isGranted ? "checkmark" : nil
                ),
                colorConfig: .init(
                    text: Color.S_0,
                    background: isGranted ? Color.clear : Color.T_9,
                    border: isGranted ? Color.T_4 : Color.clear
                ),
                sizeConfig: .init(
                    horizontalPadding: 12,
                    height: 37,
                    cornerRadius: 8
                ),
                statusConfig: .init(
                    disabled: isGranted,
                    shouldFadeOnDisabled: false,
                    borderDotted: isGranted
                )
            ) {
                action()
            }
        }
    }

    // MARK: - Child Components: Screenshot Permission Example

    private struct ScreenshotPermissionExampleSheet: View {
        @Binding var shouldShow: Bool

        var body: some View {
            VStack(alignment: .center, spacing: 38) {
                titleView
                
                HStack(alignment: .top, spacing: 20) {
                    exampleImageView(withAccess: false)
                    exampleImageView(withAccess: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 38)
            .frame(width: 697)
            .frame(height: 359)
            .overlay(alignment: .topTrailing) {
                Button {
                    shouldShow = false
                } label: {
                    Text("􀁡")
                        .styleText(
                            size: 14,
                            weight: .semibold,
                            color: Color.T_4
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 17)
                .padding(.trailing, 20)
                .offset(
                    x: 7,
                    y: -7
                )
            }
        }
        
        private var titleView: some View {
            Text(String.localized("Screenshots are used to find empty screen space, keeping Onit out of the way!", table: "Onboarding"))
                .styleText(
                    size: 18,
                    weight: .regular,
                    color: Color.S_0,
                    align: .center
                )
                .frame(maxWidth: 479)
                .padding(.top, 38)
                .padding(.horizontal, 40)
        }
        
        private func exampleImageView(withAccess: Bool) -> some View {
            VStack(alignment: .center, spacing: 12) {
                Text(withAccess ? String.localized("With: ✅ Finds empty space", table: "Onboarding") : String.localized("Without: ❌ May cover content", table: "Onboarding"))
                    .styleText(
                        size: 14,
                        weight: .regular,
                        color: Color.S_0
                    )

                Image(withAccess ? .onboardingPermissionExampleWithAccess : .onboardingPermissionExampleWithoutAccess)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .addBorder(cornerRadius: 16)
            }
        }
    }

    // MARK: - Window Positioning

    /// Repositions both windows side by side on the onboarding's screen with animation
    private func repositionWindowsSideBySide() {
        guard let onboardingWindow = OnboardingWindowManager.shared.window,
              let screen = onboardingWindow.screen else { return }

        let screenFrame = screen.visibleFrame
        let onboardingSize = onboardingWindow.frame.size
        let settingsWidth: CGFloat = 724
        let spacing: CGFloat = 20
        let totalWidth = onboardingSize.width + settingsWidth + spacing

        // Calculate the start X position to center both windows (or align to left if not enough space)
        let startX = max(screenFrame.minX, screenFrame.midX - totalWidth / 2)

        // Target position for onboarding (left)
        let onboardingTargetFrame = NSRect(
            x: startX,
            y: screenFrame.midY - onboardingSize.height / 2,
            width: onboardingSize.width,
            height: onboardingSize.height
        )

        // Target position for Settings (right)
        let settingsTargetX = startX + onboardingSize.width + spacing

        // Get Settings window info before animation
        let settingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").first
        let settingsWindow: AXUIElement? = settingsApp.flatMap { app in
            let pid = app.processIdentifier
            return pid.firstMainWindow ?? pid.findTargetWindows().first
        }
        let settingsStartFrame = settingsWindow?.getFrame()

        // Animate both windows
        let animationDuration: TimeInterval = 0.3
        let steps = 20
        let stepDuration = animationDuration / Double(steps)

        // Animate onboarding window
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            onboardingWindow.animator().setFrame(onboardingTargetFrame, display: true)
        }

        // Animate Settings window by interpolating positions
        if let settingsWindow = settingsWindow,
           let startFrame = settingsStartFrame {
            let settingsStartX = startFrame.origin.x
            let settingsStartY = startFrame.origin.y

            // Calculate target Y to center Settings vertically
            // AXUIElement uses top-left coordinate system (Y=0 at top of screen)
            // We need to calculate the Y position that centers the window
            let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? screenFrame.height
            let menuBarHeight = primaryScreenHeight - screenFrame.height - screenFrame.origin.y
            let settingsHeight = startFrame.height
            let targetY = menuBarHeight + (screenFrame.height - settingsHeight) / 2

            for i in 1...steps {
                let progress = Double(i) / Double(steps)
                // Ease-in-out curve
                let easedProgress = progress < 0.5
                    ? 2 * progress * progress
                    : 1 - pow(-2 * progress + 2, 2) / 2

                let currentX = settingsStartX + (settingsTargetX - settingsStartX) * easedProgress
                let currentY = settingsStartY + (targetY - settingsStartY) * easedProgress

                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                    _ = settingsWindow.setPosition(NSPoint(x: currentX, y: currentY))
                }
            }
        }

        // After animation completes, open Screen Recording settings
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
            screenRecordingPermissionManager.openScreenRecordingSettings()
        }
    }
}

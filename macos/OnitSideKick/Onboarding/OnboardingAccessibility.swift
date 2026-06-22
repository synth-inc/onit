//
//  OnboardingAccessibility.swift
//  Onit
//
//  Created by Loyd Kim on 4/24/25.
//

import SwiftUI

struct OnboardingAccessibility: View {
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var isHoveringSkipButton: Bool = false
    @State private var showSkipConfirmation: Bool = false

    private var instructionItems: [String] {
        [
            String.localized("・\"Tether\" Onit to your apps", table: "Onboarding"),
            String.localized("・Load context from any window", table: "Onboarding"),
            String.localized("・Insert text and code anywhere", table: "Onboarding")
        ]
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            VStack(alignment: .center, spacing: 0) {
                Image("Logo").padding(.bottom, 28)
                title
                instructions
                grantAccessButton
                privacyBlurb
            }
            .padding(.horizontal, 18)
            
            Spacer()
            
            if showSkipConfirmation {
                OnboardingSkipAccessibility(
                    showSkipConfirmation: $showSkipConfirmation
                )
            } else {
                skipAccessibilityButton
            }
        }
        .onAppear {
            AnalyticsManager.Onboarding.opened()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 22)
        .padding(.top, 134)
        .id(localization.currentLanguage)
    }
}

// MARK: - Child Components

extension OnboardingAccessibility {
    private var title: some View {
        Text(String.localized("To start, grant access to\naccessibility features", table: "Onboarding"))
            .styleText(size: 23, weight: .regular, align: .center)
            .padding(.bottom, 14)
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(instructionItems, id: \.self) { instruction in
                Text(instruction).styleText(size: 13, color: Color.S_1)
            }
        }
        .padding(.bottom, 23)
    }
    
    private var grantAccessButton: some View {
        TextButton(
            text: String.localized("Grant access", table: "Onboarding"),
            statusConfig: .init(
                fillContainer: true
            )
        ) {
            AnalyticsManager.Onboarding.grandAccessPressed()
            AccessibilityPermissionManager.shared.requestPermission()
        }
    }
    
    private func privacyBlurbText(text: String) -> some View {
        Text(text).styleText(size: 12, color: Color.S_2)
    }
    
    private var privacyBlurb: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 2) {
                Image(.lock).addIconStyles(
                    foregroundColor: Color.S_2,
                    iconSize: 13
                )
                privacyBlurbText(text: String.localized("You are always in control of the information", table: "Onboarding"))
            }
            
            privacyBlurbText(text: String.localized("Onit can access.", table: "Onboarding"))
        }
        .padding(.top, 16)
    }
    
    private var skipAccessibilityButton: some View {
        Button {
            AnalyticsManager.Onboarding.useWithoutAccessibilityPressed()
            showSkipConfirmation = true
        } label: {
            HStack(spacing: 0) {
                Text(generateSkipText())
                    .styleText(size: 13, underline: isHoveringSkipButton)
            }
        }
        .padding(.bottom, 43)
        .onHover { isHovering in
            isHoveringSkipButton = isHovering
        }
    }
}


// MARK: -  Private Functions

extension OnboardingAccessibility {
    private func generateSkipText() -> AttributedString {
        var skipText = AttributedString("")
        
        var orText = AttributedString(String.localized("Or, ", table: "Onboarding"))
        orText.foregroundColor = Color.S_1
        skipText.append(orText)

        var mainText = AttributedString(String.localized("use without accessibility →", table: "Onboarding"))
        mainText.foregroundColor = Color.S_0
        skipText.append(mainText)
        
        return skipText
    }
}

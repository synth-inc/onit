//
//  OnboardingAccessibility.swift
//  Onit
//
//  Created by Loyd Kim on 4/24/25.
//

import SwiftUI

struct OnboardingAccessibility: View {
    @State private var isHoveringSkipButton: Bool = false
    @State private var showSkipConfirmation: Bool = false
    
    private let instructionItems: [String] = [
        "・\"Tether\" Onit to your apps",
        "・Load context from any window",
        "・Insert text and code anywhere"
    ]
    
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
    }
}

// MARK: - Child Components

extension OnboardingAccessibility {
    private var title: some View {
        Text("To start, grant access to\naccessibility features")
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
            height: 40,
            fillContainer: false,
            cornerRadius: 9,
            background: Color.blue400,
            hoverBackground: Color.blue350
        ) {
            Text("Grant access")
                .styleText(size: 14, weight: .regular, color: Color.white, align: .center)
                .frame(maxWidth: .infinity)
        } action: {
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
                privacyBlurbText(text: "You are always in control of the information")
            }
            
            privacyBlurbText(text: "Onit can access.")
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
        
        var orText = AttributedString("Or, ")
        orText.foregroundColor = Color.S_1
        skipText.append(orText)
        
        var mainText = AttributedString("use without accessibility →")
        mainText.foregroundColor = Color.S_0
        skipText.append(mainText)
        
        return skipText
    }
}

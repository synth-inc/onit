//
//  OnboardingAccessibility.swift
//  Onit
//
//  Created by Loyd Kim on 4/24/25.
//

import SwiftUI

struct OnboardingAccessibility: View {
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
                OnboardingSkipAccessibility(showSkipConfirmation: $showSkipConfirmation)
            } else {
                skipAccessibilityButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
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
                Text(instruction).styleText(size: 13, color: .gray100)
            }
        }
        .padding(.bottom, 23)
    }
    
    private var grantAccessButton: some View {
        TextButton(
            action: {
                AccessibilityPermissionManager.shared.requestPermission()
            },
            height: 40,
            fillContainer: false,
            cornerRadius: 9,
            background: .blue400,
            hoverBackground: .blue350
        ) {
            Text("Grant access")
                .styleText(size: 14, weight: .regular, align: .center)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func privacyBlurbText(text: String) -> some View {
        Text(text).styleText(size: 12, color: .gray200)
    }
    
    private var privacyBlurb: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 2) {
                Image(.lock).addIconStyles(
                    foregroundColor: .gray200,
                    iconSize: 13
                )
                privacyBlurbText(text: "You are always in control of the information")
            }
            
            privacyBlurbText(text: "Onit can access.")
        }
        .padding(.top, 16)
    }
    
    private var skipAccessibilityButton: some View {
        TextButton(
            action: { showSkipConfirmation = true },
            fillContainer: false
        ) {
            HStack(spacing: 0) {
                Text("Or, ").styleText(size: 13, color: .gray100)
                Text("use without accessibility →").styleText(size: 13)
            }
        }
        .padding(.bottom, 16)
    }
}

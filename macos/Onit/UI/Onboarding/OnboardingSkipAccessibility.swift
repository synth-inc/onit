//
//  OnboardingSkipAccessibility.swift
//  Onit
//
//  Created by Loyd Kim on 4/24/25.
//

import Defaults
import SwiftUI

struct OnboardingSkipAccessibility: View {
    private var showSkipConfirmation: Binding<Bool>
    
    init(showSkipConfirmation: Binding<Bool>) {
        self.showSkipConfirmation = showSkipConfirmation
    }
    
    @State private var isHoveringClose = false
    @State private var isHoveringContinueButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            
            Text("Onit has been designed to work side-by-side with accessibility permission and relies on it for a lot of its features.")
                .styleText(size: 13, color: Color.S_1)
                .padding(0)
            HStack {
                Spacer()
                Button {
                    skipAccessibility()
                } label: {
                    Text("Yes, continue →")
                        .styleText(size: 13, underline: isHoveringContinueButton)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovering in
                    isHoveringContinueButton = isHovering
                }
            }
        }
        .onAppear {
            AnalyticsManager.Onboarding.LimitedExperience.opened()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.elevatedBG)
        .addBorder()
        .padding(.bottom, 27)
    }
}

// MARK: - Child Components

extension OnboardingSkipAccessibility {
    private var header: some View {
        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {
                Text("Continue with\na limited experience?")
                    .styleText(size: 16, weight: .bold)
                
                Spacer()
                
                Button {
                    AnalyticsManager.Onboarding.LimitedExperience.closePressed()
                    showSkipConfirmation.wrappedValue = false
                } label: {
                    Image(.smallCross).addIconStyles(
                        foregroundColor: isHoveringClose ? Color.S_0 : Color.S_2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, -6)
                .padding(.trailing, -6)
                .addAnimation(dependency: isHoveringClose)
                .onHover { isHovering in isHoveringClose = isHovering}
            }
        }
    }
}

// MARK: - Private Function

extension OnboardingSkipAccessibility {
    private func skipAccessibility() {
        AnalyticsManager.Onboarding.LimitedExperience.continuePressed()
        Defaults[.showOnboardingAccessibility] = false
    }
}

#Preview {
    OnboardingSkipAccessibility(showSkipConfirmation: .constant(true))
}

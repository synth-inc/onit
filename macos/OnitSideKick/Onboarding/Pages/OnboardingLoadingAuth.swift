//
//  OnboardingLoadingAuth.swift
//  Onit
//
//  Created by Loyd Kim on 1/16/26.
//

import SwiftUI

struct OnboardingLoadingAuth: View {
    var body: some View {
        OnboardingPage(
            footerConfig: .init(
                showBackButton: false,
                showNextButton: false
            ),
            headerTitle: {
                OnboardingTitleAndCaption(
                    customTitle: String.localized("Warming Up...", table: "Onboarding"),
                    customCaption: String.localized("Hang tight while we set up your Onit experience.", table: "Onboarding")
                )
            },
            bodyContent: {
                Loader(scaleEffect: 1.5)
                    .padding(.top, 80)
            },
            footerContent: {
                OnboardingFooterDocumentationLinks()
                Spacer()
            }
        )
    }
}

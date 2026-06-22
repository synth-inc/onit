//
//  OnboardingDiscord.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingDiscord: View {
    // MARK: - Defaults

    @Default(.currentOnboardingStep) var currentStep

    // MARK: - Body

    var body: some View {
        OnboardingPage(
            footerConfig: .init(showNextButton: false),
            headerTitle: {
                OnboardingTitleAndCaption()
            },
            bodyContent: {
                VStack(alignment: .center, spacing: 0) {
                    Image(.logo)
                        .resizable()
                        .frame(width: 59, height: 59)

                    Text(String.localized("You've been invited to join", table: "Onboarding"))
                        .styleText(
                            size: 13,
                            weight: .regular,
                            color: Color.T_1
                        )
                        .padding(.top, 18)
                        .padding(.bottom, 6)

                    Text("Onit")
                        .styleText(
                            size: 28,
                            weight: .bold
                        )
                        .padding(.bottom, 16)

                    discordInvitationButton
                }
                .frame(width: 350)
                .padding(.top, 20)
                .padding([.horizontal, .bottom], 20)
                .background(Color.T_10)
                .cornerRadius(24)
                .addBorder(
                    cornerRadius: 24,
                    stroke: Color.T_7
                )
                .padding(.top, 34)
            },
            footerContent: {
                Spacer()
                maybeLaterButton
            }
        )
        .onAppear {
            AnalyticsManager.Onboarding.discordShown()
        }
    }

    // MARK: - Child Components

    private var discordInvitationButton: some View {
        TextButton(
            colorConfig: .init(
                background: Color(hex: "5865F2") ?? Color.blue
            ),
            statusConfig: .init(
                fillContainer: true
            )
        ) {
            HStack(alignment: .center, spacing: 10) {
                Image(.logoDiscord)
                    .addIconStyles(
                        foregroundColor: Color.white,
                        iconSize: 18
                    )

                Text(String.localized("Accept Invite", table: "Onboarding"))
                    .styleText(
                        weight: .regular,
                        color: Color.white
                    )

                Image(systemName: "arrow.up.right")
                    .styleText(
                        color: Color.white
                    )
            }
        } action: {
            AnalyticsManager.Onboarding.discordAccepted()
            MenuBarDiscord.openDiscord()
        }
    }

    private var maybeLaterButton: some View {
        TextButton(
            text: String.localized("Next", table: "Onboarding"),
            colorConfig: .init(
                text: Color.S_0,
                background: Color.T_9
            )
        ) {
            AnalyticsManager.Onboarding.discordSkipped()
            toNextStep()
        }
    }

    // MARK: - Private Functions

    private func toNextStep() {
        guard let next = currentStep?.nextStep() else { return }
        currentStep = next
    }
}

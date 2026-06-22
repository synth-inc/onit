//
//  OnboardingPage.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

// MARK: - Constants

struct OnboardingPageConstants {
    static let defaultNextButtonWidth: CGFloat = 89
    static let footerButtonSize: CGFloat = 25
}

// MARK: - Types

struct OnboardingHeaderConfig {
    var spacing: CGFloat = 16
    var paddingTop: CGFloat = 44
}

struct OnboardingBodyConfig {
    var removeContentSpacer: Bool = false
}

struct OnboardingFooterConfig {
    var showBackButton: Bool = true
    var backButtonAction: (() -> Void)? = nil
    var resetAction: (() -> Void)? = nil

    var showNextButton: Bool = true
    var nextButtonText: String? = nil
    var nextButtonLeftIconName: String? = nil
    var nextButtonRightIconName: String? = nil
    var nextButtonDisabled: Binding<Bool> = .constant(false)
    var nextButtonPopoverText: Binding<String?> = .constant(nil)
    var nextButtonAction: (() -> Void)? = nil
}

// MARK: - Page View

struct OnboardingPage<
    HeaderContent: View,
    HeaderTitle: View,
    BodyContent: View,
    FooterContent: View,
    FooterCaption: View
>: View {
    // MARK: - Defaults

    @Default(.currentOnboardingStep) var currentStep

    // MARK: - Properties

    private let headerConfig: OnboardingHeaderConfig
    private let bodyConfig: OnboardingBodyConfig
    private let footerConfig: OnboardingFooterConfig
    private let currentPage: Int?

    @ViewBuilder private let headerContent: () -> HeaderContent
    @ViewBuilder private let headerTitle: () -> HeaderTitle
    @ViewBuilder private let bodyContent: () -> BodyContent
    @ViewBuilder private let footerContent: () -> FooterContent
    @ViewBuilder private let footerCaption: () -> FooterCaption

    init(
        headerConfig: OnboardingHeaderConfig = .init(),
        bodyConfig: OnboardingBodyConfig = .init(),
        footerConfig: OnboardingFooterConfig = .init(),
        currentPage: Int? = nil,

        @ViewBuilder headerContent: @escaping () -> HeaderContent = {
            EmptyView()
        },
        
        @ViewBuilder headerTitle: @escaping() -> HeaderTitle = {
            OnboardingTitleAndCaption()
        },
        
        @ViewBuilder bodyContent: @escaping () -> BodyContent = {
            EmptyView()
        },
        
        @ViewBuilder footerContent: @escaping () -> FooterContent = {
            EmptyView()
        },
        
        @ViewBuilder footerCaption: @escaping () -> FooterCaption = {
            EmptyView()
        }
    ) {
        self.headerConfig = headerConfig
        self.bodyConfig = bodyConfig
        self.footerConfig = footerConfig
        
        self.currentPage = currentPage

        self.headerContent = headerContent
        self.headerTitle = headerTitle
        self.bodyContent = bodyContent
        self.footerContent = footerContent
        self.footerCaption = footerCaption
    }

    // MARK: - States
    

    @State private var isHoveredBackButton: Bool = false
    @State private var isPressedBackButton: Bool = false

    @State private var isHoveredResetButton: Bool = false
    @State private var isPressedResetButton: Bool = false

    // MARK: - Computed Properties
    private var isFirstStep: Bool {
        currentStep?.isFirstStep ?? false
    }

    private var hasPreviousStep: Bool {
        currentStep?.previousStep() != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentSectionView
            footerSectionView
        }
    }
    
    // MARK: - Section Components
    
    private var contentSectionView: some View {
        VStack(alignment: .center, spacing: 0) {
            contentSectionHeader
            contentSectionBody
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.surface2)
        .background(Backgrounds.BrushedGlass())
    }
    
    private var footerSectionView: some View {
        HStack(alignment: .center, spacing: 0) {
            if footerConfig.showBackButton && (footerConfig.backButtonAction != nil || hasPreviousStep || isFirstStep) {
                footerBackButton
            }

            footerContent()

            footerPagination

            HStack(alignment: .center, spacing: 8) {
                footerResetButton

                if footerConfig.showNextButton {
                    OnboardingEnterButton(
                        text: footerConfig.nextButtonText ?? String.localized("Next", table: "Onboarding"),
                        leftIconName: footerConfig.nextButtonLeftIconName,
                        rightIconName: footerConfig.nextButtonRightIconName,
                        disabled: footerConfig.nextButtonDisabled,
                        popoverText: footerConfig.nextButtonPopoverText,
                        action: footerConfig.nextButtonAction
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 62)
        .overlay(
            Line(
                color: Color.T_4,
                isDotted: true
            ),
            alignment: .top
        )
        .overlay {
            footerCaption()
        }
        .background(Color.smoke)
    }
    
    // MARK: - Content Section Child Components
    
    private var contentSectionHeader: some View {
        VStack(alignment: .center, spacing: headerConfig.spacing) {
            headerContent()
            headerTitle()
        }
        .padding(.top, headerConfig.paddingTop)
    }
    
    private var contentSectionBody: some View {
        Group {
            bodyContent()

            if !bodyConfig.removeContentSpacer {
                Spacer()
            }
        }
    }

    // MARK: - Footer Section Child Components

    private func footerButton(
        isHovered: Binding<Bool>,
        isPressed: Binding<Bool>,
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Image(systemName: systemName)
            .addIconStyles(
                foregroundColor: Color.S_0,
                iconSize: 12
            )
            .frame(
                width: OnboardingPageConstants.footerButtonSize,
                alignment: .center
            )
            .frame(
                height: OnboardingPageConstants.footerButtonSize,
                alignment: .center
            )
            .addButtonEffects(
                hoverBackground: Color.S_0.opacity(0.2),
                isHovered: isHovered,
                isPressed: isPressed
            ) {
                action()
            }
    }

    @ViewBuilder
    private var footerBackButton: some View {
        if isFirstStep && AuthManager.shared.userLoggedIn {
            Button {
                logout()
            } label: {
                Text(String.localized("Logout", table: "Onboarding"))
                    .styleText(
                        fontFamily: .inter,
                        weight: .regular
                    )
            }
            .buttonStyle(PlainButtonStyle())
        } else if footerConfig.backButtonAction != nil || hasPreviousStep {
            footerButton(
                isHovered: $isHoveredBackButton,
                isPressed: $isPressedBackButton,
                systemName: "arrow.backward"
            ) {
                footerConfig.backButtonAction?() ?? toPreviousStep()
            }
        }
    }

    @ViewBuilder
    private var footerResetButton: some View {
        if let resetAction = footerConfig.resetAction {
            footerButton(
                isHovered: $isHoveredResetButton,
                isPressed: $isPressedResetButton,
                systemName: "arrow.counterclockwise"
            ) {
                resetAction()
            }
            .onHover { isHovering in
                TooltipHelpers.setTooltipOnHover(
                    isHovering: isHovering,
                    tooltipPrompt: String.localized("Reset", table: "Onboarding")
                )
            }
        }
    }

    @ViewBuilder
    private var footerPagination: some View {
        if let currentPage = self.currentPage {
            HStack(alignment: .center, spacing: 8) {
                Spacer()

                ForEach(1..<5) { page in
                    Circle()
                        .fill(Color.S_0)
                        .frame(width: 5, height: 5)
                        .opacity(page == currentPage ? 1 : 0.4)
                        .addAnimation(dependency: currentPage)
                }

                Spacer()
            }
        }
    }

    // MARK: - Private Functions

    private func toPreviousStep() {
        guard let step = currentStep?.previousStep() else { return }
        currentStep = step
    }

    private func logout() {
        AuthManager.shared.logout()
    }
}

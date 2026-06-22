//
//  OnboardingEnterButton.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingEnterButton: View {
    // MARK: - Defaults

    @Default(.currentOnboardingStep) var currentStep

    // MARK: - States

    @State private var showPopover: Bool = false

    // MARK: - Properties

    private let text: String
    private let leftIconName: String?
    private let rightIconName: String?
    @Binding private var disabled: Bool
    @Binding private var popoverText: String?
    private let action: (() -> Void)?

    init(
        text: String,
        leftIconName: String? = nil,
        rightIconName: String? = nil,
        disabled: Binding<Bool> = .constant(false),
        popoverText: Binding<String?> = .constant(nil),
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.leftIconName = leftIconName
        self.rightIconName = rightIconName
        self._disabled = disabled
        self._popoverText = popoverText
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        TextButton(
            type: .primary,
            text: text,
            iconConfig: .init(
                leftIconName: leftIconName,
                rightIconName: rightIconName
            ),
            statusConfig: .init(
                disabled: disabled
            )
        ) {
            handleAction()
        }
        .background {
            KeyListener(key: .return, modifiers: []) {
                handleAction()
            }
        }
        .popover(isPresented: $showPopover) {
            if let popoverText {
                Text(popoverText)
                    .padding(10)
                    .styleText(
                        size: 12,
                        weight: .regular
                    )
            }
        }
        .onChange(of: popoverText, initial: true) { _, text in
            let shouldShowPopover = text != nil

            if showPopover != shouldShowPopover {
                showPopover = shouldShowPopover
            }
        }
        .onChange(of: showPopover) { previousShowPopover, currentShowPopover in
            let isDismissingPopover = previousShowPopover == true && currentShowPopover == false

            if isDismissingPopover && popoverText != nil {
                popoverText = nil
            }
        }
    }

    // MARK: - Private Functions

    private func toNextStep() {
        guard let step = currentStep?.nextStep() else { return }
        currentStep = step
    }

    private func handleAction() {
        if !disabled {
            toNextStep()
            action?()
        }
    }
}

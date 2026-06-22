//
//  OnboardingTitleAndCaption.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingTitleAndCaption: View {
    // MARK: Defaults

    @Default(.currentOnboardingStep) var currentStep

    // MARK: Properties

    private let customTitle: String?
    private let customCaption: String?

    // MARK: Initializer

    init(
        customTitle: String? = nil,
        customCaption: String? = nil
    ) {
        self.customTitle = customTitle
        self.customCaption = customCaption
    }

    // MARK: - Private Variables

    private var title: String? {
        return self.customTitle ?? currentStep?.title
    }

    private var caption: String? {
        return self.customCaption ?? currentStep?.caption
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 11) {
            if let title = self.title,
               !title.isEmpty
            {
                Text(title)
                    .styleText(
                        fontFamily: .libreBaskerville,
                        size: 28,
                        weight: .regular,
                        align: .center
                    )
            }

            if let caption = self.caption,
               !caption.isEmpty
            {
                Text(caption)
                    .styleText(
                        size: 17,
                        weight: .regular,
                        color: Color.S_1,
                        align: .center
                    )
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 40)
        .addAnimation(dependency: [self.title, self.caption])
    }
}

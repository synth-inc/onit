//
//  OnboardingFooterDocumentationLinks.swift
//  Onit
//
//  Created by Loyd Kim on 1/16/26.
//

import SwiftUI

struct OnboardingFooterDocumentationLinks: View {
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 27) {
            linkButton(
                text: String.localized("Privacy", table: "Onboarding"),
                link: "https://www.getonit.ai/privacy"
            )
            linkButton(
                text: String.localized("Terms", table: "Onboarding"),
                link: "https://www.getonit.ai/terms-of-service"
            )
        }
    }
    
    // MARK: - Child Components
    
    private func linkButton(
        text: String,
        link: String
    ) -> some View {
        Button {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .center, spacing: 4) {
                Text(text)
                    .styleText(
                        size: 12,
                        weight: .regular
                    )

                Image(systemName: "arrow.up.right")
                    .styleText(
                        size: 12,
                        weight: .regular
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//
//  AuthVerifyEmailForm.swift
//  Onit
//
//  Created by Loyd Kim on 7/7/25.
//

import SwiftUI

struct AuthVerifyEmailForm: View {
    // MARK: - Properties
    
    @Binding private var email: String
    @Binding private var requestedEmailLogin: Bool
    
    private var requestEmailLoginLink: () -> Void
    
    init(
        email: Binding<String>,
        requestedEmailLogin: Binding<Bool>,
        requestEmailLoginLink: @escaping () -> Void
    ) {
        self._email = email
        self._requestedEmailLogin = requestedEmailLogin
        self.requestEmailLoginLink = requestEmailLoginLink
    }
    
    // MARK: - States
    
    @State private var isHoveredResendLinkButton: Bool = false
    @State private var isHoveredBackButton: Bool = false
    
    @State private var isPressedBackButton: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Mail")
                .padding(.bottom, 16)
            
            Text("Check your email")
                .styleText(size: 23)
            
            VStack(alignment: .center, spacing: 2) {
                Text("Click the link we sent to:")
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: .gray100
                    )
                
                Text(email)
                    .styleText(
                        size: 15,
                        weight: .regular
                    )
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 28) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Didn't get it? Check your spam folder and the spelling")
                        .styleText(
                            size: 12,
                            color: .gray200,
                            align: .center
                        )
                        .frame(maxWidth: .infinity)
                    
                    HStack(spacing: 4) {
                        Text("of your email address, or")
                            .styleText(
                                size: 12,
                                color: .gray200
                            )
                        
                        Button {
                            requestEmailLoginLink()
                        } label: {
                            Text("Resend Link")
                                .styleText(
                                    size: 12,
                                    underline: isHoveredResendLinkButton
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovering in
                            isHoveredResendLinkButton = isHovering
                        }
                    }
                }
                
                Text("← Back")
                    .frame(height: 40)
                    .padding(.horizontal, 14)
                    .addBorder(cornerRadius: 9, stroke: .gray700)
                    .addButtonEffects(
                        hoverBackground: .gray900,
                        cornerRadius: 9,
                        isHovered: $isHoveredBackButton,
                        isPressed: $isPressedBackButton
                    ) {
                        AnalyticsManager.Auth.cancelled(provider: "email")
                        isPressedBackButton = false
                        requestedEmailLogin = false
                    }
            }
        }
        .padding(.bottom, 53)
    }
}

//
//  AuthRedirectSection.swift
//  Onit
//
//  Created by Loyd Kim on 7/7/25.
//

import Defaults
import SwiftUI

struct AuthRedirectSection: View {
    @Default(.authFlowStatus) var authFlowStatus
    
    // MARK: - States
    
    @State private var isHoveredRedirectButton: Bool = false
    
    // MARK: - Private Variables
    
    private var isSignUp: Bool {
        authFlowStatus == .showSignUp
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 6) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: .gray100
                )
            
            Button {
                if isSignUp {
                    authFlowStatus = .showSignIn
                } else {
                    authFlowStatus = .showSignUp
                }
            } label: {
                Text(isSignUp ? "Sign In" : "Sign up")
                    .styleText(
                        size: 13,
                        weight: .regular,
                        underline: isHoveredRedirectButton
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                isHoveredRedirectButton = isHovering
            }
        }
    }
}

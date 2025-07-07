//
//  AuthFlow.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Defaults
import SwiftUI

struct AuthFlow: View {
    @Environment(\.appState) var appState
    
    @Default(.availableLocalModels) var availableLocalModels
    @Default(.authFlowStatus) var authFlowStatus
    
    @State private var email: String = ""
    @State private var requestedEmailLogin: Bool = false
    
    @State private var errorMessageEmail: String = ""
    
    private var userProvidedOwnModel: Bool {
        let hasLocalModel: Bool = !availableLocalModels.isEmpty
        return hasLocalModel || appState.hasUserAPITokens
    }
    
    private var showCloseButton: Bool {
        userProvidedOwnModel || appState.userLoggedIn
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 42) {
            if requestedEmailLogin {
                AuthVerifyEmailForm(
                    email: $email,
                    requestedEmailLogin: $requestedEmailLogin,
                    requestEmailLoginLink: requestEmailLoginLink
                )
            } else {
                AuthForm(
                    email: $email,
                    errorMessageEmail: $errorMessageEmail,
                    requestEmailLoginLink: requestEmailLoginLink
                )
                
                AuthRedirectSection()
                
                if !userProvidedOwnModel {
                    AuthAddModelSection()
                }
                
                Spacer()
                
                if showCloseButton {
                    closeButton
                }
            }
        }
        .onAppear {
            AnalyticsManager.Auth.opened()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 134)
    }
    
    // MARK: - Child Components
    
    private var closeButton: some View {
        TextButton(
            height: 40,
            background: .gray800
        ) {
            Text("Close")
                .frame(maxWidth: .infinity, alignment: .center)
                .styleText()
        } action: {
            authFlowStatus = .hideAuth
        }
        .padding([.top, .horizontal], 40)
        .padding(.bottom, 53)
    }
    
    // MARK: - Private Functions
    
    private func validateEmail() -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidEmailFormat = emailTest.evaluate(with: email)
        return isValidEmailFormat
    }
    
    @MainActor
    private func requestEmailLoginLink() {
        let provider = "email"
        AnalyticsManager.Auth.pressed(provider: provider)
        
        errorMessageEmail = ""

        if email.isEmpty {
            let errorMessage = "Please enter your email"
            
            AnalyticsManager.Auth.error(provider: provider, error: errorMessage)
            
            errorMessageEmail = errorMessage
        } else if !validateEmail() {
            let errorMessage = "Invalid email format"
            
            AnalyticsManager.Auth.error(provider: provider, error: errorMessage)
            
            errorMessageEmail = errorMessage
        } else {
            let client = FetchingClient()
            
            Task {
                do {
                    AnalyticsManager.Auth.requested(provider: provider)
                    
                    try await client.requestLoginLink(email: email)
                    requestedEmailLogin = true
                } catch {
                    let errorMessage = error.localizedDescription
                    
                    AnalyticsManager.Auth.failed(provider: provider, error: errorMessage)
                    
                    errorMessageEmail = errorMessage
                }
            }
        }
    }
}

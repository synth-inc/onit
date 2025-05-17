//
//  AccountTab.swift
//  Onit
//
//  Created by Jason Swanson on 4/22/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import Defaults

struct AccountTab: View {
    @Environment(\.appState) var appState
    @Environment(\.openURL) var openURL

    @State private var email: String = ""
    @State private var requestedEmail: Bool = false
    @State private var token: String = ""
    @State private var loginPassword: String = ""

    @State private var freeTrialAvailable: Bool?
    @State private var features: [SubscriptionFeature]?
    @State private var setPassword: String = ""

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if appState.account == nil {
                if !requestedEmail {
                    emailSection
                    loginPasswordSection
                }
                if requestedEmail {
                    tokenSection
                }
                google
                apple
            } else {
                subscriptionSection
                subscriptionFreeTrialAvailableSection
                subscriptionFeaturesSection
                setPasswordSection
                logoutButton
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
        }
        .onChange(of: appState.account == nil) { _, _ in
            email = ""
            requestedEmail = false
            token = ""
            loginPassword = ""
            setPassword = ""
            errorMessage = nil
        }
    }
    
    var emailSection: some View {
        VStack(spacing: 12) {
            TextField("Enter your email", text: $email)
                .textContentType(.emailAddress)
            Button("Request Magic Link") {
                handleLoginLinkRequest()
            }
            .disabled(email.isEmpty)
        }
    }

    func handleLoginLinkRequest() {
        let client = FetchingClient()
        Task {
            do {
                try await client.requestLoginLink(email: email)
                requestedEmail = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var loginPasswordSection: some View {
        VStack(spacing: 12) {
            SecureField("Password", text: $loginPassword)
            Button("Login") {
                Task {
                    await handleLoginPassword(email: email, loginPassword: loginPassword)
                }
            }
            .disabled(loginPassword.isEmpty)
        }
    }

    func handleLoginPassword(email: String, loginPassword: String) async {
        do {
            let client = FetchingClient()
            let loginResponse = try await client.loginPassword(email: email, password: loginPassword)
            handleLogin(loginResponse: loginResponse)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var tokenSection: some View {
        VStack(spacing: 12) {
            TextField("Enter your login token", text: $token)
            Button("Login") {
                handleTokenLogin()
            }
            .disabled(token.isEmpty)
        }
    }

    func handleTokenLogin() {
        let client = FetchingClient()
        Task {
            do {
                let loginResponse = try await client.loginToken(loginToken: token)
                handleLogin(loginResponse: loginResponse)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var google: some View {
        GoogleSignInButton(action: handleGoogleSignInButton)
    }

    func handleGoogleSignInButton() {
        guard let window = NSApp.keyWindow else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error as? NSError, error.domain == "com.google.GIDSignIn", error.code == -5 {
                    // The user canceled the sign-in flow
                    return
                } else if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    errorMessage = "Unknown Google sign in error"
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google identity token"
                return
            }

            Task {
                do {
                    let client = FetchingClient()
                    let loginResponse = try await client.loginGoogle(idToken: idToken)
                    handleLogin(loginResponse: loginResponse)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    var apple: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.email]
            }) { result in
                switch result {
                case .success(let authResult):
                    Task {
                        do {
                            try await handleAppleCredential(authResult)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
    }
    
    func handleAppleCredential(_ authResults: ASAuthorization) async throws {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            errorMessage = "Failed to get Apple identity token"
            return
        }
        
        let client = FetchingClient()
        let loginResponse = try await client.loginApple(idToken: identityTokenString)
        handleLogin(loginResponse: loginResponse)
    }
    
    @MainActor
    func handleLogin(loginResponse: LoginResponse) {
        TokenManager.token = loginResponse.token
        appState.account = loginResponse.account
    }

    var subscriptionSection: some View {
        HStack {
            HStack {
                Text(appState.subscriptionActive ? "Subscribed!" : "Not Subscribed >:(")
                Button("Refresh") {
                    Task {
                        await handleRefreshSubscriptionState()
                    }
                }
            }
            Spacer()
            if let subscription = appState.subscription, appState.subscriptionActive {
                HStack {
                    Button("Billing Portal Session") {
                        Task {
                            await handleCreateSubscriptionBillingPortalSession()
                        }
                    }
                    Button(subscription.cancelAtPeriodEnd ? "Renew" : "Cancel") {
                        Task {
                            await handleUpdateSubscriptionCancel(cancelAtPeriodEnd: !subscription.cancelAtPeriodEnd)
                        }
                    }
                }
            } else {
                Button("Checkout Session") {
                    Task {
                        await handleCreateSubscriptionCheckoutSession()
                    }
                }
            }
        }
    }

    func handleRefreshSubscriptionState() async {
        do {
            let client = FetchingClient()
            appState.subscription = try await client.getSubscription()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleCreateSubscriptionBillingPortalSession() async {
        do {
            let client = FetchingClient()
            let response = try await client.createSubscriptionBillingPortalSession()
            if let url = URL(string: response.sessionUrl) {
                openURL(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleUpdateSubscriptionCancel(cancelAtPeriodEnd: Bool) async {
        do {
            let client = FetchingClient()
            try await client.updateSubscriptionCancel(cancelAtPeriodEnd: cancelAtPeriodEnd)
            await handleRefreshSubscriptionState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleCreateSubscriptionCheckoutSession() async {
        do {
            let client = FetchingClient()
            let response = try await client.createSubscriptionCheckoutSession()
            if let url = URL(string: response.sessionUrl) {
                openURL(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var subscriptionFreeTrialAvailableSection: some View {
        HStack {
            Button("Is a free trial available?") {
                Task {
                    await handleFetchFreeTrialAvailable()
                }
            }
            Spacer()
            if let freeTrialAvailable = freeTrialAvailable {
                Text(freeTrialAvailable ? "It is 😏" : "It is not 😒")
            }
        }
    }

    func handleFetchFreeTrialAvailable() async {
        do {
            let client = FetchingClient()
            freeTrialAvailable = try await client.getSubscriptionFreeTrialAvailable()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var subscriptionFeaturesSection: some View {
        VStack {
            Button("Fetch the Features") {
                Task {
                    await handleFetchSubscriptionFeatures()
                }
            }
            if let features = features {
                Text("Subscription Features:")
                    .font(.system(size: 13))
                List(features) { feature in
                    Text(feature.name)
                }
            }
        }
    }

    func handleFetchSubscriptionFeatures() async {
        do {
            let client = FetchingClient()
            features = try await client.getSubscriptionFeatures()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var setPasswordSection: some View {
        VStack(spacing: 12) {
            SecureField("Create a password", text: $setPassword)
            Button("Set Your Password") {
                Task {
                    await handleSetPassword(setPassword: setPassword)
                }
            }
            .disabled(setPassword.isEmpty)
        }
    }
    
    func handleSetPassword(setPassword: String) async {
        do {
            let client = FetchingClient()
            try await client.updatePassword(password: setPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var logoutButton: some View {
        Button("Logout") {
            handleLogout()
        }
    }
    
    @MainActor
    func handleLogout() {
        TokenManager.token = nil
        appState.account = nil
    }
}

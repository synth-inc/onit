//
//  OnboardingAuthApple.swift
//  Onit
//
//  Created by Loyd Kim on 5/14/25.
//

import AuthenticationServices
import SwiftUI

// Unused as we need to sign the app with Apple's validation
struct OnboardingAuthApple: View {
    private let handleLogin: (LoginResponse) -> Void
    private let errorMessageAuth: Binding<String>
    private let signInCoordinator: SignInWithAppleCoordinator
    
    init(
        handleLogin: @escaping (LoginResponse) -> Void,
        errorMessageAuth: Binding<String>
    ) {
        self.handleLogin = handleLogin
        self.errorMessageAuth = errorMessageAuth
        
        self.signInCoordinator = SignInWithAppleCoordinator(
            handleLogin: self.handleLogin,
            errorMessageAuth: self.errorMessageAuth
        )
    }
    
    var body: some View {
        OnboardingAuthButton(
            icon: .logoApple,
            action: {
                errorMessageAuth.wrappedValue = ""
                signInCoordinator.executeAppleAuth()
            }
        )
    }
}

class SignInWithAppleCoordinator:
    NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let handleLogin: (LoginResponse) -> Void
    private let errorMessageAuth: Binding<String>
    
    init(
        handleLogin: @escaping (LoginResponse) -> Void,
        errorMessageAuth: Binding<String>
    ) {
        self.handleLogin = handleLogin
        self.errorMessageAuth = errorMessageAuth
        super.init()
    }
    
    @MainActor
    func executeAppleAuth() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        configureRequest(request)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.email]
    }
    
    // ASAuthorizationControllerDelegate
    
    private func handleAppleCredential(_ authorization: ASAuthorization) async throws {
        guard
            let credentials = authorization.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            errorMessageAuth.wrappedValue = "Failed to get Apple identity token"
            return
        }
        
        let client = FetchingClient()
        let loginResponse = try await client.loginApple(idToken: identityTokenString)
        handleLogin(loginResponse)
    }
    
    /// Handling Authorization Success
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task {
            do {
                try await handleAppleCredential(authorization)
            } catch {
                errorMessageAuth.wrappedValue = error.localizedDescription
            }
        }
    }
    
    /// Handling Authorization Error
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        errorMessageAuth.wrappedValue = error.localizedDescription
    }
    
    // ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = NSApplication.shared.windows.first(
            where: { $0.isKeyWindow }
        ) ?? NSApplication.shared.windows.first else {
            // TECHNICALLY, this should never happen, but having a fallback is good practice.
            errorMessageAuth.wrappedValue = "Unable to present Apple authentication dialog."
            return NSApplication.shared.mainWindow ?? NSWindow()
        }
        
        return window
    }
}

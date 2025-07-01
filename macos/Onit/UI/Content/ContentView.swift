//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import SwiftUI

struct ContentView: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) private var state
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @Namespace private var animation
    
    @Default(.mode) var mode
    @Default(.panelWidth) var panelWidth
    @Default(.authFlowStatus) var authFlowStatus
    @Default(.showOnboardingAccessibility) var showOnboardingAccessibility
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    @Default(.availableLocalModels) var availableLocalModels
    
    static let bottomPadding: CGFloat = 0
    
    private var shouldShowOnboardingAccessibility: Bool {
        let accessibilityNotGranted = accessibilityPermissionManager.accessibilityPermissionStatus != .granted
        return accessibilityNotGranted && showOnboardingAccessibility
    }
    
    private var userProvidedOwnModel: Bool {
        let hasLocalModel: Bool = !availableLocalModels.isEmpty
        return hasLocalModel || appState.hasUserAPITokens
    }
    
    private var showAuthFlow: Bool {
        authFlowStatus != .hideAuth
    }
    
    private var showToolbar: Bool {
        !shouldShowOnboardingAccessibility && !showAuthFlow
    }
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state.showFileImporter },
            set: { state.showFileImporter = $0 }
        )
    }
    
    private var errorContext: Context? {
        state.pendingContextList.first { context in
            if case .auto(let autoContext) = context {
                return autoContext.appContent["error"] != nil
            }
            return false
        }
    }
    
    // MARK: - Private Functions
    
    @ViewBuilder
    private func alertView<Content: View>(
        isPresented: Bool,
        id: String,
        content: Content
    ) -> some View {
        if isPresented {
            content
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .matchedGeometryEffect(id: id, in: animation)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if shouldShowOnboardingAccessibility {
                VStack(spacing: 0) {
                    if state.showChatView {
                        OnboardingAccessibility().transition(.opacity)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else if showAuthFlow {
                AuthFlow()
            } else {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        if showToolbar {
                            Toolbar()
                        }
                        
                        VStack(spacing: 0) {
                            if state.showChatView { ChatView().transition(.opacity) }
                            else { Spacer() }
                        }
                    }
                    
                    if state.showChatView {
                        ZStack {
                            alertView(
                                isPresented: showTwoWeekProTrialEndedAlert,
                                id: "trial_ended_alert",
                                content: TwoWeekProTrialEndedAlert()
                            )
                            
                            alertView(
                                isPresented: appState.showFreeLimitAlert,
                                id: "free_limit_alert",
                                content: FreeLimitAlert()
                            )
                            
                            alertView(
                                isPresented: appState.showProLimitAlert,
                                id: "pro_limit_alert",
                                content: ProLimitAlert()
                            )
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showTwoWeekProTrialEndedAlert)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.showFreeLimitAlert)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.showProLimitAlert)
                    }
                }
            }
        }
        .background(Color.black)
        .addBorder(
            cornerRadius: 14,
            lineWidth: 2,
            stroke: .gray600
        )
        .edgesIgnoringSafeArea(.top)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded({ handleViewClicked() })
        )
        .fileImporter(
            isPresented: showFileImporterBinding,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .addAnimation(dependency: state.showChatView)
        .onAppear {
            // Prevents edge cases where incorrect state may have been set.
            // While this isn't likely, having an extra layer of security makes sure to keep the UX in-line with expectations.
            checkShouldHideOrShowAuthFlow()
            checkCanAccessRemoteModels()
            
            if !hasClosedTrialEndedAlert {
                if let subscriptionStatus = appState.subscription?.status {
                    if subscriptionStatus == "active" {
                        hasClosedTrialEndedAlert = true
                    } else if subscriptionStatus == "canceled",
                       let trialEndDate = appState.subscription?.trialEnd
                    {
                        let today = getTodayAsEpochDate()
                        let trialExpired = today >= trialEndDate
                        
                        if trialExpired {
                            showTwoWeekProTrialEndedAlert = true
                        }
                    }
                }
            }
        }
        .onChange(of: appState.userLoggedIn) { _, loggedIn in
            if loggedIn {
                authFlowStatus = .hideAuth
            } else if !loggedIn && !userProvidedOwnModel {
                authFlowStatus = .showSignUp
            }
        }
        .onChange(of: userProvidedOwnModel) { _, providedOwnModel in
            if providedOwnModel {
                authFlowStatus = .hideAuth
            } else if !providedOwnModel && !appState.userLoggedIn {
                authFlowStatus = .showSignUp
            }
        }
        .onChange(of: appState.canAccessRemoteModels) { _, canAccessRemoteModels in
            if !canAccessRemoteModels {
                mode = .local
                Defaults[.modelModeToggleShortcutDisabled] = true
            } else {
                Defaults[.modelModeToggleShortcutDisabled] = false
            }
        }
    }
    
    private func checkShouldHideOrShowAuthFlow() {
        if appState.userLoggedIn {
            authFlowStatus = .hideAuth
        } else if userProvidedOwnModel {
            authFlowStatus = .hideAuth
        } else {
            authFlowStatus = .showSignUp
        }
    }
    
    private func checkCanAccessRemoteModels() {
        if !appState.canAccessRemoteModels {
            mode = .local
            Defaults[.modelModeToggleShortcutDisabled] = true
        } else {
            Defaults[.modelModeToggleShortcutDisabled] = false
        }
    }
    
    private func handleViewClicked() {
        state.textFocusTrigger.toggle()
        
        state.notifyDelegates { $0.panelBecomeKey(state: state) }
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            state.addContext(urls: urls)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif

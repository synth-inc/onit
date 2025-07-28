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
    @Default(.visibleModelIds) var visibleModelIds
    @Default(.remoteModel) var remoteModel
    
    @State private var modelProvidersManager = ModelProvidersManager.shared
    
    static let bottomPadding: CGFloat = 0
    
    private var shouldShowOnboardingAccessibility: Bool {
        let accessibilityNotGranted = accessibilityPermissionManager.accessibilityPermissionStatus != .granted
        return accessibilityNotGranted && showOnboardingAccessibility
    }
    
    private var showAuthFlow: Bool {
        authFlowStatus != .hideAuth
    }
    
    private var showToolbar: Bool {
        !shouldShowOnboardingAccessibility && !showAuthFlow
    }
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state?.showFileImporter ?? false },
            set: { state?.showFileImporter = $0 }
        )
    }
    
    private var errorContext: Context? {
        state?.pendingContextList.first { context in
            if case .auto(let autoContext) = context {
                return autoContext.appContent["error"] != nil
            }
            return false
        }
    }
    
    private var canAccessRemoteModels: Bool {
        !appState.listedModels.isEmpty
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
                    if state?.showChatView == true {
                        OnboardingAccessibility().transition(.opacity)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .onAppear {
                    if appState.account == nil {
                        authFlowStatus = .showSignUp
                    } else {
                        authFlowStatus = .hideAuth
                    }
                }
            } else if showAuthFlow {
                AuthFlow()
            } else {
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        if showToolbar {
                            Toolbar(mode: mode)
                        }
                        
                        VStack(spacing: 0) {
                            if state?.showChatView == true { ChatView().transition(.opacity) }
                            else { Spacer() }
                        }
                    }
                    
                    if state?.showChatView == true {
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
                .onAppear {
                    /// Checking if any of the API tokens added by the user is invalid, at least once every 24 hours.
                    Task {
                        let now: Date = Date()
                        var shouldCheck: Bool = false
                        
                        if let mostRecentCheckDate = Defaults[.lastCheckedValidRemoteTokens] {
                            /// Throttle remote token validity check to once every 24 hours.
                            shouldCheck = now.timeIntervalSince(mostRecentCheckDate) >= 86400 /// 24 hours in seconds
                        } else {
                            /// First-time check.
                            shouldCheck = true
                        }
                        
                        guard shouldCheck else { return }
                        
                        await checkRemoteTokenValidity()
                        Defaults[.lastCheckedValidRemoteTokens] = now
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
        .addAnimation(dependency: state?.showChatView)
        .onAppear {
            setModeAndValidRemoteModelWithAuth()
            
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
        .onChange(of: appState.userLoggedIn) { _, userLoggedIn in
            setModeAndValidRemoteModelWithAuth()
            
            if userLoggedIn && canAccessRemoteModels {
                mode = .remote
            }
        }
        .onChange(of: availableLocalModels) {_, localModelsList in
            if !appState.userLoggedIn {
                let canAccessLocalModels = !localModelsList.isEmpty
                
                if !canAccessLocalModels && canAccessRemoteModels {
                    mode = .remote
                }
                
                let cannotAccessModels = !canAccessRemoteModels && !canAccessLocalModels
                
                authFlowStatus = cannotAccessModels ? .showSignUp : .hideAuth
            }
        }
        .onChange(of: modelProvidersManager.numberRemoteProvidersInUse) { _, _ in
            appState.setModeAndValidRemoteModel()
            
            if canAccessRemoteModels {
                mode = .remote
            }
        }
        .onChange(of: visibleModelIds) { _, _ in
            appState.setModeAndValidRemoteModel()
            
            if canAccessRemoteModels {
                mode = .remote
            }
        }
    }
    
    private func setModeAndValidRemoteModelWithAuth() {
        appState.setModeAndValidRemoteModel()
        
        if appState.userLoggedIn {
            authFlowStatus = .hideAuth
        } else {
            let canAccessLocalModels = !availableLocalModels.isEmpty
            let cannotAccessModels = !canAccessRemoteModels && !canAccessLocalModels
            
            authFlowStatus = cannotAccessModels ? .showSignUp : .hideAuth
        }
    }
    
    private func checkRemoteTokenValidity() async {
        let providerTokens: [AIModel.ModelProvider: String?] = [
            .openAI: Defaults[.openAIToken],
            .anthropic: Defaults[.anthropicToken],
            .xAI: Defaults[.xAIToken],
            .googleAI: Defaults[.googleAIToken],
            .deepSeek: Defaults[.deepSeekToken],
            .perplexity: Defaults[.perplexityToken]
        ]
        
        await withTaskGroup(
            of: Void.self,
            returning: Void.self
        ) { group in
            for (provider, providerToken) in providerTokens {
                if let token = providerToken {
                    group.addTask {
                        await TokenValidationManager.shared.validateToken(provider: provider, token: token)
                    }
                }
            }
        }
    }
    
    private func handleViewClicked() {
        state?.textFocusTrigger.toggle()
        
        if let state = state {
            state.notifyDelegates { $0.panelBecomeKey(state: state) }
        }
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            state?.addContext(urls: urls)
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

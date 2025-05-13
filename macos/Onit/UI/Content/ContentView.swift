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
    
    @Default(.showOnboardingAccessibility) var showOnboardingAccessibility
    @Default(.onboardingAuthState) var onboardingAuthState
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    
    static let idealWidth: CGFloat = 400
    static let bottomPadding: CGFloat = 0
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state.showFileImporter },
            set: { state.showFileImporter = $0 }
        )
    }
    
    private var shouldShowOnboardingAccessibility: Bool {
        let accessibilityPermissionGranted = accessibilityPermissionManager.accessibilityPermissionStatus == .granted
        return !accessibilityPermissionGranted && showOnboardingAccessibility
    }
    
    private var shouldShowOnboardingAuth: Bool {
        let loggedOut = appState.account == nil
        let showOnboardingAuth = onboardingAuthState != .hideAuth
        return loggedOut && showOnboardingAuth
    }

    var body: some View {
        HStack(spacing: -TetheredButton.width / 2) {
            TetheredButton()
            
            ZStack(alignment: .top) {
                if shouldShowOnboardingAccessibility {
                    VStack(spacing: 0) {
                        if state.showChatView {
                            OnboardingAccessibility().transition(.opacity)
                        } else {
                            Spacer()
                        }
                    }
                    .frame(width: TetherAppsManager.minOnitWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.black)
                    .onDisappear {
                        if appState.account == nil {
                            onboardingAuthState = .showSignUp
                        }
                    }
                } else if shouldShowOnboardingAuth {
                    OnboardingAuth(isSignUp: onboardingAuthState == .showSignUp)
                } else {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 38)
                            
                            PromptDivider()
                            
                            if state.showChatView { ChatView().transition(.opacity) }
                            else { Spacer() }
                        }
                        
                        if showTwoWeekProTrialEndedAlert {
                            TwoWeekProTrialEndedAlert()
                        } else if appState.showFreeLimitAlert {
                            FreeLimitAlert()
                        } else if appState.showProLimitAlert {
                            ProLimitAlert()
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
        }
        .buttonStyle(PlainButtonStyle())
        .toolbar {
            if !shouldShowOnboardingAccessibility {
                ToolbarItem(placement: .navigation) {
                    ToolbarAddButton()
                }
                ToolbarItem(placement: .automatic) { TetheredToAppView() }
                ToolbarItem(placement: .automatic) { Spacer() }
                ToolbarItem(placement: .primaryAction) {
                    Toolbar()
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded({ state.handlePanelClicked() })
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
            if !hasClosedTrialEndedAlert {
                if let subscriptionStatus = appState.subscription?.status{
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

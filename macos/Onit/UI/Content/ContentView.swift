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
    
    @Default(.panelWidth) var panelWidth
    @Default(.authFlowStatus) var authFlowStatus
    @Default(.showOnboardingAccessibility) var showOnboardingAccessibility
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    
    static let bottomPadding: CGFloat = 0
    
    private var shouldShowOnboardingAccessibility: Bool {
        let accessibilityNotGranted = accessibilityPermissionManager.accessibilityPermissionStatus != .granted
        return accessibilityNotGranted && showOnboardingAccessibility
    }
    
    private var showToolbar: Bool {
        !shouldShowOnboardingAccessibility && appState.account != nil
    }
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state.showFileImporter },
            set: { state.showFileImporter = $0 }
        )
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        if appState.account == nil {
                            authFlowStatus = .showSignUp
                        } else {
                            authFlowStatus = .hideAuth
                        }
                    }
                } else if appState.account == nil {
                    AuthFlow()
                } else {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 38)
                            
                            PromptDivider()
                            
                            if state.showChatView {
                                ChatView().transition(.opacity)
                            } else {
                                Spacer()
                            }
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
            if showToolbar {
                ToolbarItem(placement: .navigation) {
                    ToolbarLeft()
                }
                ToolbarItem(placement: .automatic) { TetheredToAppView() }
                ToolbarItem(placement: .automatic) { Spacer() }
                ToolbarItem(placement: .primaryAction) {
                    ToolbarRight()
                }
            }
        }
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

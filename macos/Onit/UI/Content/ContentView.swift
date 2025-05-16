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
    
    @Default(.panelWidth) var panelWidth
    @Default(.mode) var mode
    @Default(.showOnboarding) var showOnboarding
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    
    static let bottomPadding: CGFloat = 0
    
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
                if showOnboarding {
                    Onboarding()
                } else if appState.account == nil {
                    AuthFlow()
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
            if !showOnboarding {
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
        .onChange(of: appState.account) {
            if appState.account != nil {
                mode = .remote
            }
        }
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

//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import SwiftUI

struct ContentView: View {
    @Environment(\.windowState) private var state
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @Default(.showOnboarding) var showOnboarding
    
    static let idealWidth: CGFloat = 400
    static let bottomPadding: CGFloat = 0
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state.showFileImporter },
            set: { state.showFileImporter = $0 }
        )
    }
    
    private var shouldShowOnboarding: Bool {
        let accessibilityPermissionGranted = accessibilityPermissionManager.accessibilityPermissionStatus == .granted
        return !accessibilityPermissionGranted && showOnboarding
    }

    var body: some View {
        HStack(spacing: -TetheredButton.width / 2) {
            TetheredButton()
            
            ZStack(alignment: .top) {
                if shouldShowOnboarding {
                    VStack(spacing: 0) {
                        if state.showChatView {
                            OnboardingAccessibility().transition(.opacity)
                        } else {
                            Spacer()
                        }
                    }
                    .frame(width: ContentView.idealWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 38)
                        
                        PromptDivider()
                        
                        if state.showChatView { ChatView().transition(.opacity) }
                        else { Spacer() }
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
            if !shouldShowOnboarding {
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

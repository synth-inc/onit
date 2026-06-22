//
//  ContentViewFooterNotification.swift
//  Onit
//
//  Created by Loyd Kim on 6/11/25.
//

import Defaults
import SwiftUI

struct ContentViewFooterNotification: View {
    @Environment(\.appState) private var appState
    
    let footerNotification: FooterNotification
    
    init(footerNotification: FooterNotification) {
        self.footerNotification = footerNotification
    }
    
    typealias HeaderText = String
    typealias ButtonText = String
    typealias ButtonIcon = ImageResource?
    typealias ButtonIconSize = CGFloat
    
    private var content: (HeaderText, ButtonText, ButtonIcon, ButtonIconSize) {
        switch footerNotification {
        case .discord:
            return (String.localized("Get the latest news & say hi to friends!", table: "Sidekick"), String.localized("Join Discord", table: "Sidekick"), .logoDiscord, 18)
        default:
            return (String.localized("New update available!", table: "Sidekick"), String.localized("Download Update", table: "Sidekick"), .lightning, 16)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 0) {
                DividerHorizontal()
                
                VStack(alignment: .center, spacing: 13) {
                    Text(content.0)
                        .styleText(size: 16, align: .center)
                    
                    TextButton(
                        text: content.1,
                        iconConfig: .init(
                            leftIconImage: content.2
                        ),
                        colorConfig: .init(
                            text: Color.white,
                            background: Color.blue400
                        ),
                        sizeConfig: .init(
                            text: 13,
                            horizontalPadding: 16,
                            height: 36
                        ),
                        alignmentConfig: .init(
                            gap: 8
                        )
                    ) {
                        action()
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity)
            }
            
            IconButton(
                icon: .cross,
                iconSize: 10,
                action: dismiss
            )
            .padding([.top, .trailing], 10)
        }
    }
}

// MARK: - Private Functions

extension ContentViewFooterNotification {
    private func dismiss() {
        switch footerNotification {
        case .discord:
            appState.removeDiscordFooterNotifications()
        default:
            appState.removeUpdateFooterNotifications()
        }
    }
    
    private func action() {
        switch footerNotification {
        case .discord:
            MenuBarDiscord.openDiscord()
        default:
            appState.checkForAvailableUpdateWithDownload()
        }
    }
}

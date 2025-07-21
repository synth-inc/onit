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
            return ("Get the latest news & say hi to friends!", "Join Discord", .logoDiscord, 18)
        default:
            return ("New update available!", "Download Update", .lightning, 16)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 0) {
                DividerHorizontal(foregroundColor: .gray600)
                
                VStack(alignment: .center, spacing: 13) {
                    Text(content.0)
                        .styleText(size: 16, align: .center)
                    
                    TextButton(
                        iconSize: content.3,
                        gap: 4,
                        height: 36,
                        fillContainer: false,
                        background: .blue400,
                        hoverBackground: .blue350,
                        fontSize: 13,
                        fontWeight: .regular,
                        icon: content.2,
                        text: content.1
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
        .background(.black)
    }
}

// MARK: - Private Functions

extension ContentViewFooterNotification {
    private func dismiss() {
        switch footerNotification {
        case .discord:
            appState?.removeDiscordFooterNotifications()
        default:
            appState?.removeUpdateFooterNotifications()
        }
    }
    
    private func action() {
        switch footerNotification {
        case .discord:
            if let appState = appState {
                MenuJoinDiscord.openDiscord(appState)
            }
        default:
            appState?.checkForAvailableUpdateWithDownload()
        }
    }
}

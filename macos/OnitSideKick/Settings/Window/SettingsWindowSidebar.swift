//
//  SettingsWindowSidebar.swift
//  Onit
//
//  Created by Loyd Kim on 2/23/26.
//

import Defaults
import SwiftUI

struct SettingsWindowSidebar: View {
    // MARK: - Defaults

    @Default(.settingsPage) private var settingsPage

    // MARK: - Environments

    @Environment(\.appState) var appState

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBarSpacer
            ScrollView {
                rootOptions
                sidekickOptions

                #if DEBUG || ONIT_BETA
                devOptions
                #endif
            }
            .padding(.bottom, 16)
        }
        .frame(width: 224)
        .background(Backgrounds.BrushedGlass())
        .background(Color.T_6)
        .overlay(
            Rectangle()
                .fill(Color.T_6)
                .frame(width: 1)
                .frame(maxHeight: .infinity),
            alignment: .trailing
        )
    }

    // MARK: - Child Components: Title Bar Spacer

    /// Reserves vertical space for the native window title bar buttons (traffic lights).
    private var titleBarSpacer: some View {
        Color.clear
            .frame(height: 38)
    }

    // MARK: - Child Components

    private var rootOptions: some View {
        sidebarSection(
            pages: SettingsPage.rootCases,
            showDivider: false
        )
    }

    private var sidekickOptions: some View {
        sidebarSection(
            title: "Sidekick",
            pages: SettingsPage.panelCases
        )
    }

    #if DEBUG || ONIT_BETA
    private var devOptions: some View {
        sidebarSection(
            title: String.localized("Dev Pages", table: "Settings"),
            pages: SettingsPage.devCases
        )
    }
    #endif

    private func sidebarSection(
        title: String? = nil,
        pages: [SettingsPage],
        showDivider: Bool = true
    ) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            if showDivider {
                DividerHorizontal()
            }

            if let title = title {
                Text(title)
                    .styleText(
                        size: 13,
                        weight: .semibold,
                        color: Color.S_0
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }

            if !pages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(pages, id: \.self) { page in
                        sidebarButton(for: page)
                    }
                }
                .padding([.horizontal, .bottom], 8)
            }
        }
    }

    private func sidebarButton(for page: SettingsPage) -> some View {
        TextButton(
            type: .clear,
            sizeConfig: .init(
                textWeight: .regular,
                horizontalPadding: 8,
                height: 32
            ),
            statusConfig: .init(
                selected: settingsPage == page
            )
        ) {
            HStack(alignment: .center, spacing: 10) {
                sidebarIcon(for: page)

                Text(page.name)
                    .styleText(size: 13)

                Spacer()

                if let notificationCount = getNotificationCount(for: page) {
                    Text("\(notificationCount)")
                        .frame(width: 18, height: 18)
                        .background(Color.red500)
                        .cornerRadius(999)
                        .styleText(
                            size: 11,
                            weight: .regular,
                            color: Color.white
                        )
                }
            }
        } action: {
            settingsPage = page
        }
    }

    private func sidebarIcon(for page: SettingsPage) -> some View {
        Image(systemName: page.icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color.white)
            .frame(
                width: 20,
                alignment: .center
            )
            .frame(
                height: 20,
                alignment: .center
            )
            .background(page.iconBackgroundColor)
            .cornerRadius(5)
    }

    // MARK: - Private Functions

    private func getNotificationCount(for settingsPage: SettingsPage) -> Int? {
        switch settingsPage {
        case .setup:
            return appState.setupBadgeCount
        default:
            return nil
        }
    }
}

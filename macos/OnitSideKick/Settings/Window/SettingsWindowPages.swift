//
//  SettingsWindowPages.swift
//  Onit
//
//  Created by Loyd Kim on 2/23/26.
//

import Defaults
import SwiftUI

struct SettingsWindowPages: View {
    // MARK: - Defaults
    
    @Default(.settingsPage) private var settingsPage
    
    // MARK: - Body
    
    var body: some View {
        if settingsPage.hasCustomScrolling {
            contentView
                .frame(maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                contentView
            }
        }
    }
    
    // MARK: - Child Components
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !settingsPage.rendersOwnHeader {
                pageViewHeaderView
            }
            pageContentView
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var pageViewHeaderView: some View {
        pageViewHeaderTitleView()
    }
    
    private func pageViewHeaderTitleView(text: String? = nil) -> some View {
        Text(text ?? settingsPage.name)
            .styleText(
                size: 22,
                weight: .bold
            )
    }
    
    @ViewBuilder
    private var pageContentView: some View {
        switch self.settingsPage {

        /// Root Pages
        case .general:
            SettingsGeneral()
        case .accountAndBilling:
            SettingsAccountAndBilling()
        case .setup:
            SettingsSetup()
        case .memories:
            SettingsMemories()
        case .about:
            SettingsAbout()

        case .disabledAppsAndSites:
            SettingsDisabledAppsAndSites()

        /// Sidekick Pages
        case .panelBehavior:
            SettingsSidekickBehavior()
        case .panelModels:
            SettingsSidekickModels()
        case .panelPrompts:
            SettingsSidekickPrompts()
        case .panelShortcuts:
            SettingsSidekickShortcuts()
        case .panelContext:
            SettingsSidekickContext()
        case .panelWebSearch:
            SettingsSidekickWebSearch()

        /// Dev Pages
        #if DEBUG || ONIT_BETA
        case .experimental:
            SettingsExperimental()
        case .sidekickDatabase:
            SettingsSidekickDatabase()
        case .sidekickDebug:
            SettingsSidekickDebug()
        #endif
        }
    }
}

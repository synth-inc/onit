//
//  SettingsDisabledAppsAndSites.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import Defaults
import SwiftUI

struct SettingsDisabledAppsAndSites: View {
    //MARK: - Defaults
    
    @Default(.featureDisableRules) private var featureDisableRules
    @Default(.sidekickDisabledInPrivateBrowser) private var sidekickDisabledInPrivateBrowser
    
    // MARK: - Private Variables
    
    private let featureDisableManager = FeatureDisableManager.shared
    
    private var disabledAppsSectionIsDisabled: Bool {
        // Check for menu default feature status
        let status = featureDisableManager.currentDisableStatus(for: .menuDefault)
        
        switch status {
        case .disabledGloballyIndefinitely, .disabledGloballyTemporarily(_):
            return true
        case .disabledGloballyTimeRange(let startTime, let endTime):
            let isWithinDisabledTimeRange = featureDisableManager.checkIsWithinDisabledTimeRange(
                DisableRuleTimeRange(
                    startTime: startTime,
                    endTime: endTime
                )
            )
            
            return isWithinDisabledTimeRange
        default:
            return false
        }
    }
    
    private var appDisableRules: [(
        id: String,
        rule: FeatureDisableRule,
        app: AppDisableRule,
        expirationDate: Date?,
        timeRange: DisableRuleTimeRange?
    )] {
        self.featureDisableRules.compactMap { disableRule in
            guard let app = disableRule.app else { return nil }
            // Only show rules that affect menuDefault features
            guard disableRule.features.intersection(.menuDefault) != [] else { return nil }

            return (
                id: disableRule.id.uuidString,
                rule: disableRule,
                app: app,
                expirationDate: disableRule.expirationDate,
                timeRange: disableRule.timeRange
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        SettingsTitleView(
            text: String.localized("You can enable and disable Sidekick to appear in specific apps or websites from the menu bar. Click the Onit icon in the menu bar and select one of the \"Disable\" options for the currently active app or website.", table: "Settings")
        )
        
        SettingsPageSection {
            disablePrivateBrowserSection
            DividerHorizontal()
            DisableEverywhereSection()
        }
        
        disabledAppsSection
    }
    
    // MARK: - Child Components: Disabled Private Browser section
    
    private var disablePrivateBrowserSection: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Automatically Disable in Private Browsing", table: "Settings")
            ),
            isOn: $sidekickDisabledInPrivateBrowser
        )
    }
    
    // MARK: - Child Components: Disabled Apps Section
    
    private var disabledAppsSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Disabled Apps", table: "Settings"))) {
            if self.appDisableRules.isEmpty {
                disabledAppsEmptySection
            } else {
                disabledAppsListSection
            }
        }
    }

    private var disabledAppsEmptySection: some View {
        SettingsPageSubsection {
            Text(String.localized("No Apps or Sites Added", table: "Settings"))
                .frame(maxWidth: .infinity, alignment: .center)
                .styleText(
                    size: 12,
                    weight: .regular,
                    color: Color.T_1
                )
        }
    }
    
    private var disabledAppsListSection: some View {
        SettingsPageSubsection(vertical: .init()) {
            ForEach(
                Array(self.appDisableRules.enumerated()),
                id: \.element.id
            ) { index, appDisableRule in
                DisabledAppSection(
                    rule: appDisableRule.rule,
                    app: appDisableRule.app,
                    expirationDate: appDisableRule.expirationDate
                )
                
                if index < self.appDisableRules.count - 1 {
                    DividerHorizontal()
                        .padding(.vertical, 12)
                }
            }
        }
        .opacity(self.disabledAppsSectionIsDisabled ? 0.4 : 1)
        .allowsHitTesting(!self.disabledAppsSectionIsDisabled)
    }
}

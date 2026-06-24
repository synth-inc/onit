//
//  DisableEverywhereSection.swift
//  Onit
//
//  Created by Loyd Kim on 9/9/25.
//

import Defaults
import SwiftUI

struct DisableEverywhereSection: View {
    // MARK: - Defaults
    
    @Default(.featureDisableRules) private var featureDisableRules
    
    // MARK: - States
    
    @State private var disableRuleExpirationText: String? = nil
    
    // MARK: - Private Variables
    
    private let featureDisableManager = FeatureDisableManager.shared
    private let featureDisableWindowManager = FeatureDisableWindowManager.shared
    
    private var globalDisableRule: FeatureDisableRule? {
        return featureDisableManager.findGlobalDisableRule(for: .menuDefault)
    }
    
    private var globalDisableRuleIsActive: Bool {
        return globalDisableRule != nil
    }
    
    private var disabledText: String? {
        if let expirationText = disableRuleExpirationText {
            return expirationText
        } else if let timeRange = globalDisableRule?.timeRange {
            let startTimeText = DateHelpers.formatDateToTimeOfDay(timeRange.startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(timeRange.endTime)
            return String(format: String.localized("%@ - %@, Every Day", table: "Settings"), startTimeText, endTimeText)
        } else if globalDisableRuleIsActive {
            return String.localized("Indefinitely", table: "Settings")
        } else {
            return nil
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        SettingsPageSubsection(
            horizontal: .init(alignment: globalDisableRuleIsActive ? .top : .center),
            header: .init(
                title: String.localized("Disable SideKick Everywhere", table: "Settings"),
                subtitle: disabledText
            )
        ) {
            SimpleButton(
                text: globalDisableRuleIsActive ?
                        String.localized("Cancel", table: "Settings") :
                        String.localized("Disable Everywhere...", table: "Settings")
            ) {
                if globalDisableRuleIsActive {
                    featureDisableManager.removeDisableRule(for: .menuDefault)
                } else {
                    featureDisableWindowManager.createWindow()
                }
            }
        }
        .onReceive(
            Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        ) { _ in
            if let expirationDate = globalDisableRule?.expirationDate {
                let expirationText = DateHelpers.formatDateToTimeRemaining(expirationDate)
                disableRuleExpirationText = expirationText
            } else {
                disableRuleExpirationText = nil
            }
        }
    }
}

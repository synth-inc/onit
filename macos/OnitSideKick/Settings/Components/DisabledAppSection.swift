//
//  DisabledAppSection.swift
//  Onit
//
//  Created by Loyd Kim on 9/9/25.
//

import Defaults
import SwiftUI

struct DisabledAppSection: View {
    // MARK: - Defaults
    
    @Default(.featureDisableRules) private var featureDisableRules
    
    // MARK: - Properties
    
    private let rule: FeatureDisableRule
    private let app: AppDisableRule
    private let expirationDate: Date?
    
    init(
        rule: FeatureDisableRule,
        app: AppDisableRule,
        expirationDate: Date? = nil
    ) {
        self.rule = rule
        self.app = app
        self.expirationDate = expirationDate
    }
    
    // MARK: - States
    
    @State private var disableRuleExpirationText: String? = nil
    
    // MARK: - Private Variables
    
    private let featureDisableManager = FeatureDisableManager.shared
    
    private var currentRule: FeatureDisableRule? {
        return featureDisableRules.first(where: { $0.id == rule.id })
    }
    
    private var disabledText: String {
        if let expirationText = self.disableRuleExpirationText {
            return expirationText
        } else if let timeRange = self.currentRule?.timeRange {
            let startTimeText = DateHelpers.formatDateToTimeOfDay(timeRange.startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(timeRange.endTime)
            return String(format: String.localized("%@ - %@, Every Day", table: "Settings"), startTimeText, endTimeText)
        } else {
            return String.localized("Indefinitely", table: "Settings")
        }
    }
    
    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                if let bundleUrl = app.bundleUrl {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: bundleUrl.path))
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(5)
                } else {
                    Rectangle()
                        .fill(Color.S_5)
                        .frame(width: 24, height: 24)
                        .cornerRadius(5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .styleText(
                            size: 13,
                            weight: .regular
                        )
                    
                    Text(disabledText)
                        .styleText(
                            size: 12,
                            weight: .regular,
                            color: Color.T_1
                        )
                }
            }
            
            Spacer()
            
            SimpleButton(text: String.localized("Remove", table: "Settings")) {
                featureDisableManager.removeDisableRule(for: rule.features, app: self.app)
            }
        }
        .onReceive(
            Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        ) { _ in
            if let expirationDate = self.currentRule?.expirationDate {
                let expirationText = DateHelpers.formatDateToTimeRemaining(expirationDate)
                self.disableRuleExpirationText = expirationText
            } else {
                self.disableRuleExpirationText = nil
            }
        }
    }
}

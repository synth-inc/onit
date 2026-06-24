//
//  FeatureDisableWindowView.swift
//  Onit
//
//  Created by Loyd Kim on 9/9/25.
//

import AppKit
import SwiftUI

enum FeatureDisableWindowDisableType {
    case expirationTime
    case disableIndefinitely
    case setSpecificHours
}

struct FeatureDisableWindowView: View {
    // MARK: - Properties

    private let foregroundWindow: TrackedWindow?
    private let disableType: FeatureDisableWindowDisableType

    // MARK: - Initializer

    init(
        foregroundWindow: TrackedWindow?,
        disableType: FeatureDisableWindowDisableType = .expirationTime
    ) {
        self.foregroundWindow = foregroundWindow
        self.disableType = disableType
    }

    // MARK: - Observed Objects

    @ObservedObject private var localizationManager = LocalizationManager.shared

    // MARK: - States

    @State private var expirationTime: TimeInterval? = nil
    @State private var disableIndefinitely: Bool = false
    @State private var setSpecificHours: Bool = false

    @State private var startTime: Date = Date()

    @State private var endTime: Date = Calendar.current.date(
        bySettingHour: 23,
        minute: 59,
        second: 0,
        of: Date()
    ) ?? Date()

    @State private var errorMessage: String? = nil

    // MARK: - Private Variables

    private let featureDisableManager = FeatureDisableManager.shared
    private let featureDisableWindowManager = FeatureDisableWindowManager.shared

    private let oneMinute: TimeInterval = 60
    private let oneHour: TimeInterval = 60 * 60

    private var titleText: String {
        if let window = self.foregroundWindow?.element {
            let appName = WindowHelpers.getWindowAppName(window: window)
            return String(format: String.localized("Disable SideKick in %@", table: "Settings"), appName)
        } else {
            return String.localized("Disable SideKick Everywhere", table: "Settings")
        }
    }

    private var disableRuleExpirationDate: Date? {
        guard let expirationTime = self.expirationTime else { return nil }
        return DateHelpers.getExpirationDate(expiresIn: expirationTime)
    }

    private var disableRuleExpirationDateText: String? {
        guard let expirationDate = self.disableRuleExpirationDate else { return nil }
        return DateHelpers.formatDateToTimeRemaining(expirationDate)
    }

    private var disableRuleTimeRange: DisableRuleTimeRange? {
        guard self.setSpecificHours else { return nil }
        return DisableRuleTimeRange(
            startTime: startTime,
            endTime: endTime
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Text(self.titleText)
                    .styleText(size: 15)

                HStack(alignment: .top, spacing: 6) {
                    Text(String.localized("Time:", table: "Settings"))
                        .styleText(weight: .regular)

                    VStack(alignment: .leading, spacing: 12) {
                        radioButtons

                        specificHoursPickers
                    }
                    .padding(.top, 2)
                }
            }
            .padding(20)

            DividerHorizontal(foregroundColor: Color.S_0.opacity(0.1))

            footer
        }
        .frame(width: 402)
        .background(Color.baseBG.opacity(0.7))
        .background(Backgrounds.BrushedGlass())
        .cornerRadius(10)
        .onAppear {
            switch self.disableType {
            case .expirationTime:
                self.expirationTime = self.oneMinute * 5
                self.disableIndefinitely = false
                self.setSpecificHours = false

            case .disableIndefinitely:
                self.disableIndefinitely = true
                self.expirationTime = nil
                self.setSpecificHours = false

            case .setSpecificHours:
                self.setSpecificHours = true
                self.expirationTime = nil
                self.disableIndefinitely = false
            }
        }
    }

    // MARK: - Child Components

    private var radioButtons: some View {
        Group {
            Picker("", selection: $expirationTime) {
                Text(String.localized("5 mins", table: "Settings")).tag(oneMinute * 5).padding(.bottom, 8)
                Text(String.localized("15 mins", table: "Settings")).tag(oneMinute * 15).padding(.bottom, 8)
                Text(String.localized("30 mins", table: "Settings")).tag(oneMinute * 30).padding(.bottom, 8)
                Text(String.localized("Until Tomorrow", table: "Settings")).tag(oneHour * 24)
            }
            .pickerStyle(RadioGroupPickerStyle())

            Picker("", selection: $disableIndefinitely) {
                Text(String.localized("Indefinitely", table: "Settings")).tag(true)
            }
            .pickerStyle(RadioGroupPickerStyle())

            Picker("", selection: $setSpecificHours) {
                Text(String.localized("Specific Hours", table: "Settings")).tag(true)
            }
            .pickerStyle(RadioGroupPickerStyle())
        }
        .onChange(of: self.expirationTime) { _, expirationTime in
            if expirationTime != nil {
                self.disableIndefinitely = false
                self.setSpecificHours = false
            }
        }
        .onChange(of: self.disableIndefinitely) { _, disableIndefinitely in
            if disableIndefinitely {
                self.expirationTime = nil
                self.setSpecificHours = false
            }
        }
        .onChange(of: self.setSpecificHours) { _, setSpecificHours in
            if setSpecificHours {
                self.expirationTime = nil
                self.disableIndefinitely = false
            }
        }
        .onChange(of: [self.startTime, self.endTime]) { _, new in
            let startTime = new[0]
            let endTime = new[1]

            if startTime == endTime {
                self.errorMessage = String.localized("Specified time must be within a range.", table: "Settings")
            } else {
                self.errorMessage = nil
            }
        }
    }

    @ViewBuilder
    private var specificHoursPickers: some View {
        if setSpecificHours {
            HStack(alignment: .center, spacing: 8) {
                Text(String.localized("From:", table: "Settings"))
                    .styleText(
                        size: 13,
                        weight: .regular
                    )

                TimePicker(time: self.$startTime)

                Text(String.localized("To:", table: "Settings"))
                    .styleText(
                        size: 13,
                        weight: .regular
                    )

                TimePicker(time: self.$endTime)
            }
            .padding(.leading, 8)
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 4) {
            if let errorMessage = self.errorMessage {
                Text(errorMessage)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.red500
                    )
            }

            Spacer()

            SimpleButton(text: String.localized("Cancel", table: "Settings")) {
                self.close()
            }

            SimpleButton(
                disabled: self.errorMessage != nil,
                text: String.localized("Done", table: "Settings"),
                textColor: Color.white,
                action: {
                    self.disableFeature()
                    self.close()
                },
                background: Color.blue
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Private Functions

    private func close() {
        self.featureDisableWindowManager.closeWindow()
    }

    private func disableFeature() {
        let appDisableRule = self.featureDisableManager.createAppDisableRule(self.foregroundWindow)

        self.featureDisableManager.addDisableRule(
            features: .menuDefault,
            app: appDisableRule,
            expirationDate: disableRuleExpirationDate,
            timeRange: self.disableRuleTimeRange
        )
    }
}

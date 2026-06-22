//
//  SettingsSidekickBehavior.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import Defaults
import SwiftUI

struct SettingsSidekickBehavior: View {
    // MARK: - Defaults

    @Default(.enableSidebar) private var panelEnabled
    @Default(.fontSize) private var fontSize
    @Default(.lineHeight) private var lineHeight
    @Default(.panelWidth) private var panelWidth
    @Default(.usePinnedMode) private var usePinnedMode
    @Default(.autoContextOnLaunchTethered) private var autoContextOnLaunchTethered
    @Default(.autoContextOnLaunchPinned) private var autoContextOnLaunchPinned
    @Default(.stopMode) private var stopMode
    @Default(.tetheredButtonHiddenApps) private var tetheredButtonHiddenApps
    @Default(.tetheredButtonHideAllApps) private var tetheredButtonHideAllApps
    @Default(.tetheredButtonHideAllAppsTimerDate) private var tetheredButtonHideAllAppsTimerDate
    @Default(.showHighlightedTextInput) private var showHighlightedTextInput
    @Default(.autoAddHighlightedTextToContext) private var autoAddHighlightedTextToContext

    // MARK: - Observations

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    // MARK: - States

    @State private var currentTime: Date = Date()
    @State private var timerUpdateTask: Task<Void, Never>? = nil

    // MARK: - Private Variables

    private var accessibilityGranted: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    private var isPinnedMode: Bool {
        usePinnedMode ?? true
    }

    private var isHideAllAppsTimerActive: Bool {
        guard let timerDate = tetheredButtonHideAllAppsTimerDate else { return false }
        return timerDate > currentTime
    }

    private var remainingTimeString: String {
        guard let timerDate = tetheredButtonHideAllAppsTimerDate else { return "" }

        let timeInterval = timerDate.timeIntervalSince(currentTime)
        if timeInterval <= 0 { return String.localized("Expired", table: "Sidekick") }

        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        if minutes > 0 {
            return String(format: String.localized("%dm %ds", table: "Sidekick"), minutes, seconds)
        } else {
            return String(format: String.localized("%ds", table: "Sidekick"), seconds)
        }
    }
    
    private var shouldShowHiddenApps: Bool {
        return
            !featureFlagsManager.usePinnedMode ||
            isHideAllAppsTimerActive ||
            tetheredButtonHideAllApps
    }
    
    private var shouldshowHideEverywhereStatus: Bool {
        return
            isHideAllAppsTimerActive ||
            tetheredButtonHideAllApps
    }
    
    private var shouldShowHiddenAppsList: Bool {
        return !featureFlagsManager.usePinnedMode
    }

    // MARK: - Body

    var body: some View {
        Group {
            enableSection
            displayModeSection
            behaviorSection
            appearanceSection
            highlightedTextSection

            if shouldShowHiddenApps {
                hiddenAppsSection
            }
        }
        .onAppear {
            startTimerUpdateTaskIfNeeded()
        }
        .onDisappear {
            stopTimerUpdateTask()
        }
        .onChange(of: tetheredButtonHideAllAppsTimerDate) { _, newValue in
            if newValue != nil {
                startTimerUpdateTaskIfNeeded()
            } else {
                stopTimerUpdateTask()
            }
        }
    }

    // MARK: - Child Components: Enable Section

    private var enableSection: some View {
        SettingsPageSection {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Enable Sidekick", table: "Sidekick"),
                    subtitle: String.localized("A context-aware AI assistant that lives at the edge of your screen and answers questions about anything you're looking at.", table: "Sidekick")
                ),
                isOn: $panelEnabled
            )
        }
    }

    // MARK: - Child Components: Display Mode Section

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsPageSection(title: .init(text: String.localized("Display Mode", table: "Sidekick"))) {
                if !accessibilityGranted {
                    accessibilityWarning
                } else {
                    displayModeButtons
                    displayModeDescription
                    DividerHorizontal()
                    autoContextOnLaunchToggle
                }
            }
        }
    }

    private var accessibilityWarning: some View {
        SettingsPageSubsection(
            vertical: .init(
                spacing: 8
            ),
            header: .init(
                title: String.localized("To use Pinned or Tethered mode, enable Accessibility permission for Onit.", table: "Sidekick")
            )
        ) {
            TextButton(
                text: String.localized("Enable Accessibility Permission", table: "Sidekick"),
                colorConfig: .init(
                    text: Color.white,
                    background: Color.blue
                ),
                sizeConfig: .init(
                    text: 13,
                    height: 32
                )
            ) {
                AccessibilityPermissionManager.shared.requestPermission()
            }
        }
    }

    private var displayModeButtons: some View {
        HStack(spacing: 8) {
            displayModeButton(
                icon: "pin.fill",
                title: String.localized("Pinned", table: "Sidekick"),
                subtitle: String.localized("Fixed position", table: "Sidekick"),
                isSelected: isPinnedMode
            ) {
                let oldValue = isPinnedMode ? "pinned" : "tethered"
                AnalyticsManager.Settings.General.displayModePressed(oldValue: oldValue, newValue: "pinned")
                FeatureFlagManager.shared.togglePinnedMode(true)
            }

            displayModeButton(
                icon: "rectangle.split.2x1",
                title: String.localized("Tethered", table: "Sidekick"),
                subtitle: String.localized("Attaches to apps", table: "Sidekick"),
                isSelected: !isPinnedMode
            ) {
                let oldValue = isPinnedMode ? "pinned" : "tethered"
                AnalyticsManager.Settings.General.displayModePressed(oldValue: oldValue, newValue: "tethered")
                FeatureFlagManager.shared.togglePinnedMode(false)
            }
        }
    }

    private func displayModeButton(
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .styleText(size: 11)
                Text(subtitle)
                    .styleText(
                        size: 9,
                        color: Color.S_1
                    )
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 76, alignment: .center)
            .background(isSelected ? Color.blue : Color.T_8)
//            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var displayModeDescription: some View {
        Group {
            if isPinnedMode {
                Text(String.localized("Onit will always appear on the right side of your screen. You will only have one Onit panel at any given time. Other applications will be resized to make room for Onit.", table: "Sidekick"))
                    .styleText(size: 12, color: Color.S_2)
            } else {
                Text(String.localized("Onit will attach to your applications. There can be one Onit panel for each application window. If you move your app, Onit will move with it.", table: "Sidekick"))
                    .styleText(size: 12, color: Color.S_2)
            }
        }
        .padding(.top, 4)
    }

    private var autoContextOnLaunchToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !featureFlagsManager.usePinnedMode {
                SettingsPageSubsection(
                    header: .init(
                        title: String.localized("Add Current Window on Launch", table: "Sidekick"),
                        subtitle: String.localized("Adds context from the current window whenever Onit opens in Tethered mode.", table: "Sidekick")
                    ),
                    isOn: self.$autoContextOnLaunchTethered
                )
            } else {
                SettingsPageSubsection(
                    header: .init(
                        title: String.localized("Add Current Window on Launch", table: "Sidekick"),
                        subtitle: String.localized("Adds context from the current window whenever Onit opens in Pinned mode, and automatically updates context as you switch between windows.", table: "Sidekick")
                    ),
                    isOn: self.$autoContextOnLaunchPinned
                )
            }
        }
    }
    
    // MARK: - Child Components: Behavior Section

    private var behaviorSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Behavior", table: "Sidekick"))) {
            stopModeSelector
        }
    }

    private var stopModeSelector: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Stop Mode", table: "Sidekick"),
                subtitle: String.localized("Controls what happens when you stop generation.", table: "Sidekick")
            ),
            dropdown: .init(
                placeholder: String.localized("Select mode", table: "Sidekick"),
                options: StopMode.allCases.map { mode in
                    .init(
                        id: UUID(),
                        name: mode == .removePartial ? String.localized("Remove Partial", table: "Sidekick") : String.localized("Leave Partial", table: "Sidekick"),
                        isSelected: stopMode == mode,
                        action: {
                            stopMode = mode
                            FeatureFlagManager.shared.setStopModeByUser(mode)
                        }
                    )
                }
            )
        )
    }
    
    // MARK: - Child Components: Appearance Section

    private var appearanceSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Appearance", table: "Sidekick"))) {
            sliderSetting(
                title: String.localized("Panel Width", table: "Sidekick"),
                value: $panelWidth,
                range: 300...600,
                step: 10,
                unit: "px",
                onReset: { _panelWidth.reset() }
            )
            
            DividerHorizontal()

            sliderSetting(
                title: String.localized("Font Size", table: "Sidekick"),
                value: $fontSize,
                range: 10...24,
                step: 1,
                unit: "pt",
                onReset: { _fontSize.reset() }
            )
            
            DividerHorizontal()

            sliderSetting(
                title: String.localized("Line Height", table: "Sidekick"),
                value: $lineHeight,
                range: 1.0...2.5,
                step: 0.1,
                unit: "",
                format: "%.1f",
                onReset: { _lineHeight.reset() }
            )
        }
    }

    private func sliderSetting(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String,
        format: String = "%.0f",
        onReset: @escaping () -> Void
    ) -> some View {
        SettingsPageSubsection(
            vertical: .init(spacing: 8)
        ) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .styleText(size: 13)

                Slider(value: value, in: range, step: step)

                Text("\(String(format: format, value.wrappedValue))\(unit)")
                    .styleText(size: 13)
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }

            HStack(alignment: .center, spacing: 0) {
                Spacer()
                Button {
                    onReset()
                } label: {
                    Text(String.localized("Restore Default", table: "Sidekick"))
                        .styleText(
                            size: 12,
                            color: Color.blue
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Child Components: Highlighted Text Section

    private var highlightedTextSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Highlighted Text", table: "Sidekick"))) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Show highlighted text input", table: "Sidekick"),
                    subtitle: String.localized("Display highlighted text in the input area.", table: "Sidekick")
                ),
                isOn: self.$showHighlightedTextInput
            )
            
            DividerHorizontal()

            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Auto-add highlighted text to context", table: "Sidekick"),
                    subtitle: String.localized("Automatically add highlighted text as context when launching Onit.", table: "Sidekick")
                ),
                isOn: self.$autoAddHighlightedTextToContext
            )
        }
    }
    
    // MARK: - Child Components: Hidden Apps Section

    private var hiddenAppsSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Hidden Apps", table: "Sidekick"))) {
            if shouldshowHideEverywhereStatus {
                hideEverywhereStatus
            }

            if shouldShowHiddenAppsList {
                if shouldshowHideEverywhereStatus {
                    DividerHorizontal()
                }
                hiddenAppsList
            }
        }
    }

    private var hideEverywhereStatus: some View {
        SettingsPageSubsection(
            vertical: .init(spacing: 8),
            header: .init(title: String.localized("Hide Everywhere", table: "Sidekick"))
        ) {
            if isHideAllAppsTimerActive {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String.localized("Hidden for 1 hour", table: "Sidekick"))
                            .styleText(size: 13)
                        Text(String(format: String.localized("Time remaining: %@", table: "Sidekick"), remainingTimeString))
                            .styleText(size: 11, color: Color.S_3)
                    }

                    Spacer()

                    TextButton(
                        text: String.localized("Unhide", table: "Sidekick"),
                        colorConfig: .init(
                            background: Color.T_8
                        ),
                        sizeConfig: .init(
                            text: 12,
                            height: 32
                        )
                    ) {
                        cancelHideAllAppsTimer()
                    }
                }
                .padding(8)
                .background(Color.orange500.opacity(0.1))
                .cornerRadius(6)
            } else if tetheredButtonHideAllApps {
                HStack {
                    Text(String.localized("Hidden permanently", table: "Sidekick"))
                        .styleText(size: 13)

                    Spacer()

                    TextButton(
                        text: String.localized("Unhide", table: "Sidekick"),
                        colorConfig: .init(
                            background: Color.T_8
                        ),
                        sizeConfig: .init(
                            text: 12,
                            height: 32
                        )
                    ) {
                        tetheredButtonHideAllApps = false
                    }
                }
                .padding(8)
                .background(Color.red500.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }

    private var hiddenAppsList: some View {
        SettingsPageSubsection(
            vertical: .init(spacing: 8),
            header: .init(title: String.localized("Applications where you've disabled the Onit entry point.", table: "Sidekick"))
        ) {
            if tetheredButtonHiddenApps.isEmpty {
                Text(String.localized("You haven't disabled Onit on any apps yet.", table: "Sidekick"))
                    .styleText(size: 13, color: Color.S_4)
                    .italic()
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(tetheredButtonHiddenApps.keys.sorted()), id: \.self) { appName in
                        HStack {
                            Text(appName)
                                .styleText(size: 13)

                            Spacer()

                            TextButton(
                                text: String.localized("Unhide", table: "Sidekick"),
                                colorConfig: .init(
                                    background: Color.T_8
                                ),
                                sizeConfig: .init(
                                    text: 12,
                                    height: 32
                                )
                            ) {
                                tetheredButtonHiddenApps.removeValue(forKey: appName)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.T_8.opacity(0.5))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    // MARK: - Private Functions

    private func cancelHideAllAppsTimer() {
        tetheredButtonHideAllAppsTimerDate = nil
        tetheredButtonHideAllApps = false
    }

    private func startTimerUpdateTaskIfNeeded() {
        guard tetheredButtonHideAllAppsTimerDate != nil, timerUpdateTask == nil else { return }

        timerUpdateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    await MainActor.run {
                        currentTime = Date()

                        if let timerDate = tetheredButtonHideAllAppsTimerDate,
                           timerDate <= currentTime {
                            tetheredButtonHideAllAppsTimerDate = nil
                            tetheredButtonHideAllApps = false
                        }
                    }
                }
            }
        }
    }

    private func stopTimerUpdateTask() {
        timerUpdateTask?.cancel()
        timerUpdateTask = nil
    }
}

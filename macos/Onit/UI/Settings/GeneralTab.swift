import Defaults
import PostHog
import ServiceManagement
import SwiftUI
import AppKit

struct GeneralTab: View {
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    @Default(.panelWidth) var panelWidth
    
    @Default(.launchShortcutToggleEnabled) var launchShortcutToggleEnabled
    @Default(.createNewChatOnPanelOpen) var createNewChatOnPanelOpen
    @Default(.openOnMouseMonitor) var openOnMouseMonitor
    @Default(.usePinnedMode) var usePinnedMode
    @Default(.autoContextOnLaunchTethered) var autoContextOnLaunchTethered
    
    @State var isLaunchAtStartupEnabled: Bool = SMAppService.mainApp.status == .enabled
    @State var isAnalyticsEnabled: Bool = PostHogSDK.shared.isOptOut() == false
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    private var accessibilityGranted: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var isPinnedMode: Bool {
        usePinnedMode ?? true
    }
    
    var body: some View {
        Form {
            GeneralTabPlanAndBilling()
            
            GeneralTabAccount()
            
            launchOnStartupSection
            
            displayModeSection
            
            analyticsSection
                        
            appearanceSection
            
            // experimentalSection
        }
        .formStyle(.grouped)
    }
    
    var launchOnStartupSection: some View {
        SettingsSection(
            iconSystem: "power",
            title: "Auto start"
        ) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Run onit when my computer starts")
                        .font(.system(size: 13))

                    Spacer()

                    Toggle("", isOn: $isLaunchAtStartupEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .onChange(of: isLaunchAtStartupEnabled, initial: false) { _, _ in
                toggleLaunchAtStartup()
            }
        }
    }

    var displayModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Button {
                        let oldValue = isPinnedMode ? "pinned" : "tethered"
                        AnalyticsManager.Settings.General.displayModePressed(oldValue: oldValue, newValue: "pinned")
                        FeatureFlagManager.shared.togglePinnedMode(true)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 16))
                            Text("Pinned")
                                .font(.system(size: 11))
                            Text("Fixed position")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isPinnedMode ? Color.accentColor : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .opacity(accessibilityGranted ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!accessibilityGranted)
                    
                    Button {
                        let oldValue = isPinnedMode ? "pinned" : "tethered"
                        AnalyticsManager.Settings.General.displayModePressed(oldValue: oldValue, newValue: "tethered")
                        FeatureFlagManager.shared.togglePinnedMode(false)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "rectangle.split.2x1")
                                .font(.system(size: 16))
                            Text("Tethered")
                                .font(.system(size: 11))
                            Text("Attaches to apps")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!isPinnedMode ? Color.accentColor : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .opacity(accessibilityGranted ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!accessibilityGranted)
                }
                if !accessibilityGranted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To use Pinned or Tethered mode, enable Accessibility permission for Onit.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray200)
                        Button(action: {
                            if let url = URL(string: MenuCheckForPermissions.link) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.open")
                                Text("Enable Accessibility Permission")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        if isPinnedMode {
                            Text("Onit will always appear on the right side of your screen. You will only have one Onit panel at any given time. Other applications will be resized to make room for Onit.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray200)
                        } else {
                            Text("Onit will attach to your applications. There can be one Onit panel for each application window. If you move your app, Onit will move with it.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray200)
                        }
                    }
                }
                if !featureFlagsManager.usePinnedMode {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Add Current Window on Launch")
                                    .font(.system(size: 13))
                                Spacer()
                                Toggle("", isOn: $autoContextOnLaunchTethered)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                SettingInfoButton(
                                    title: "Add Current Window on Launch",
                                    description:
                                        "When enabled, Onit automatically reads the tethered window and adds its text as context whenever the panel opens.",
                                    defaultValue: "on",
                                    valueType: "Bool"
                                )
                            }
                            Text("Adds context from the current window whenever Onit opens in Tethered mode.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray200)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                Text("Display Mode")
            }
        }
    }
    
    var analyticsSection: some View {
        SettingsSection(
            iconSystem: "chart.bar.xaxis",
            title: "Analytics"
        ) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Enable analytics")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $isAnalyticsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                Text("Help us improve your experience 🚀\nWe collect anonymous usage data to enhance performance and fix issues faster.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray200)
            }
            .onChange(of: isAnalyticsEnabled, initial: false) {
                toggleAnalyticsOptOut()
            }
        }
    }

    var appearanceSection: some View {
        SettingsSection(
            iconSystem: "paintbrush",
            title: "Appearance"
        ) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Panel Width")
                        Slider(
                            value: $panelWidth,
                            in: 300...600,
                            step: 10.0
                        )
                        Text("\(Int(panelWidth))px")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
           
                    HStack {
                        Spacer()
                        Button("Restore Default") {
                            _panelWidth.reset()
                        }
                        .controlSize(.small)
                    }   
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Slider(
                            value: $fontSize,
                            in: 10...24,
                            step: 1.0
                        )
                        Text("\(Int(fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Restore Default") {
                            _fontSize.reset()
                        }
                        .controlSize(.small)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Line Height")
                        Slider(
                            value: $lineHeight,
                            in: 1.0...2.5,
                            step: 0.1
                        )
                        Text(String(format: "%.1f", lineHeight))
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Restore Default") {
                            _lineHeight.reset()
                        }
                        .controlSize(.small)
                    }
                }
                
                GeneralTabAudio()
                
                //                VStack(alignment: .leading, spacing: 8) {
                //                    Text("Panel Position")
                //                        .font(.system(size: 13))
                //
                //                    HStack(spacing: 8) {
                //                        ForEach(PanelPosition.allCases, id: \.self) { position in
                //                            Button {
                //                                panelPosition = position
                //                                state.panel?.updatePosition()
                //                            } label: {
                //                                VStack(spacing: 4) {
                //                                    Image(systemName: position.systemImage)
                //                                        .font(.system(size: 16))
                //                                    Text(position.rawValue)
                //                                        .font(.system(size: 11))
                //                                }
                //                                .frame(maxWidth: .infinity)
                //                                .padding(.vertical, 8)
                //                                .background(panelPosition == position ? Color.accentColor : Color.clear)
                //                                .clipShape(RoundedRectangle(cornerRadius: 6))
                //                                .contentShape(Rectangle())
                //                            }
                //                            .buttonStyle(.plain)
                //                        }
                //                    }
                //                }
            }
        }
    }
    
//    var experimentalSection: some View {
//        Section {
//            VStack(spacing: 16) {
//                HStack {
//                    Text("Use launch shortcut as a toggle")
//                        .font(.system(size: 13))
//                    SettingInfoButton(
//                        title: "Use Launch Shortcut as a Toggle",
//                        description:
//                            "Enable this to use the launch shortcut (CMD+Zero by default) as a toggle: press once to show the panel, press again to hide it.",
//                        defaultValue: "off",
//                        valueType: "Bool"
//                    )
//                    Spacer()
//                    Toggle(
//                        "",
//                        isOn: $launchShortcutToggleEnabled
//                    )
//                    .toggleStyle(.switch)
//                    .controlSize(.small)
//                }
//
//                HStack {
//                    Text("Create new chat on panel open")
//                        .font(.system(size: 13))
//                    SettingInfoButton(
//                        title: "Create New Chat on Panel Open",
//                        description:
//                            "Enable this to start a new chat each time the panel opens. You still access your previous conversations with the up arrow.",
//                        defaultValue: "off",
//                        valueType: "Bool"
//                    )
//                    Spacer()
//                    Toggle(
//                        "",
//                        isOn: $createNewChatOnPanelOpen
//                    )
//                    .toggleStyle(.switch)
//                    .controlSize(.small)
//                }
//
//                HStack {
//                    Text("Open on mouse monitor")
//                        .font(.system(size: 13))
//                    SettingInfoButton(
//                        title: "Open on Mouse Monitor",
//                        description:
//                            "Enable this to open Onit on the monitor where your mouse cursor is currently located. This can help ensure Onit appears where your attention is focused.",
//                        defaultValue: "off",
//                        valueType: "Bool"
//                    )
//                    Spacer()
//                    Toggle(
//                        "",
//                        isOn: $openOnMouseMonitor
//                    )
//                    .toggleStyle(.switch)
//                    .controlSize(.small)
//                }
//            }
//        } header: {
//            HStack {
//                Image(systemName: "gearshape")
//                Text("Experimental Features")
//            }
//        }
//    }

    private func toggleLaunchAtStartup() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Error : \(error)")
        }
    }
    
    private func toggleAnalyticsOptOut() {
        if PostHogSDK.shared.isOptOut() {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }
}

#Preview {
    GeneralTab()
}

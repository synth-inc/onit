import Defaults
import PostHog
import ServiceManagement
import SwiftUI

struct GeneralTab: View {
    @Environment(\.model) var model
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    @Default(.panelPosition) var panelPosition
    @Default(.isRegularApp) var isRegularApp
    @Default(.launchShortcutToggleEnabled) var launchShortcutToggleEnabled
    @Default(.createNewChatOnPanelOpen) var createNewChatOnPanelOpen
    @Default(.openOnMouseMonitor) var openOnMouseMonitor

    @State var isLaunchAtStartupEnabled: Bool = SMAppService.mainApp.status == .enabled
    @State var isAnalyticsEnabled: Bool = PostHogSDK.shared.isOptOut() == false
    
    var body: some View {
        Form {
            launchOnStartupSection
            
            analyticsSection
            
            appearanceSection
            
            experimentalSection
        }
        .formStyle(.grouped)
        .padding()
    }
    
    var launchOnStartupSection: some View {
        Section {
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
            .onChange(of: isLaunchAtStartupEnabled, initial: false) { old, new in
                toggleLaunchAtStartup()
            }
        } header: {
            HStack {
                Image(systemName: "power")
                Text("Auto start")
            }
        }
    }
    
    var analyticsSection: some View {
        Section {
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
        } header: {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                Text("Analytics")
            }
        }
    }

    var appearanceSection: some View {
        Section {
            VStack(spacing: 16) {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Panel Position")
                        .font(.system(size: 13))

                    HStack(spacing: 8) {
                        ForEach(PanelPosition.allCases, id: \.self) { position in
                            Button {
                                panelPosition = position
                                model.updatePanelPosition()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: position.systemImage)
                                        .font(.system(size: 16))
                                    Text(position.rawValue)
                                        .font(.system(size: 11))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(panelPosition == position ? Color.accentColor : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Image(systemName: "paintbrush")
                Text("Appearance")
            }
        }
    }
    
    var experimentalSection: some View {
        Section {
            VStack(spacing: 16) {
                HStack {
                    Text("Use Onit as a standard application")
                        .font(.system(size: 13))
                    SettingInfoButton(
                        title: "Use Onit as a standard application",
                        description:
                            "When enabled, Onit will be a standard application, meaing it can be accessed from the Dock and Spotlight.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
                    Spacer()
                    Toggle(
                        "",
                        isOn: $isRegularApp
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                // Re-draw the panel on change
                .onChange(of: isRegularApp, initial: false) {
                    model.closePanel()
                    model.showPanel()
                }

                HStack {
                    Text("Use launch shortcut as a toggle")
                        .font(.system(size: 13))
                    SettingInfoButton(
                        title: "Use Launch Shortcut as a Toggle",
                        description:
                            "Enable this to use the launch shortcut (CMD+Zero by default) as a toggle: press once to show the panel, press again to hide it.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
                    Spacer()
                    Toggle(
                        "",
                        isOn: $launchShortcutToggleEnabled
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                HStack {
                    Text("Create new chat on panel open")
                        .font(.system(size: 13))
                    SettingInfoButton(
                        title: "Create New Chat on Panel Open",
                        description:
                            "Enable this to start a new chat each time the panel opens. You still access your previous conversations with the up arrow.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
                    Spacer()
                    Toggle(
                        "",
                        isOn: $createNewChatOnPanelOpen
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                HStack {
                    Text("Open on mouse monitor")
                        .font(.system(size: 13))
                    SettingInfoButton(
                        title: "Open on Mouse Monitor",
                        description:
                            "Enable this to open Onit on the monitor where your mouse cursor is currently located. This can help ensure Onit appears where your attention is focused.",
                        defaultValue: "off",
                        valueType: "Bool"
                    )
                    Spacer()
                    Toggle(
                        "",
                        isOn: $openOnMouseMonitor
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
        } header: {
            HStack {
                Image(systemName: "gearshape")
                Text("Experimental Features")
            }
        }
    }

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

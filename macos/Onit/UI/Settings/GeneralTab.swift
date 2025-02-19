import Defaults
import PostHog
import ServiceManagement
import SwiftUI

struct GeneralTab: View {
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    @Default(.panelPosition) var panelPosition

    @State var isLaunchAtStartupEnabled: Bool = SMAppService.mainApp.status == .enabled
    @State var isAnalyticsEnabled: Bool = PostHogSDK.shared.isOptOut() == false

    var body: some View {
        Form {
            launchOnStartupSection
            
            analyticsSection

            appearanceSection
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
                    Text("Disable analytics")
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
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: position.systemImage)
                                        .font(.system(size: 16))
                                    Text(position.rawValue)
                                        .font(.system(size: 11))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .background {
                                    if panelPosition == position {
                                        Color(.blue300)
                                    }
                                }
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

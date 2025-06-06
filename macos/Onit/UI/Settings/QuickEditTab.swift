//
//  QuickEditTab.swift
//  Onit
//
//  Created by Kévin Naudin on 06/20/2025.
//

import SwiftUI
import Defaults
import KeyboardShortcuts

struct QuickEditTab: View {
    @Default(.quickEditConfig) private var config
    @State private var shortcutText: String = KeyboardShortcuts.Name.quickEdit.shortcutText
    @ObservedObject private var permissionManager = ScreenRecordingPermissionManager.shared
    
    var body: some View {
        Form {
            Section {

            } header: {
                Text("Quick Edit")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text(
                    "Quick Edit enhances your text editing experience by providing instant access to Onit's AI capabilities. When you highlight text in any application, a subtle hint appears, allowing you to quickly transform, analyze, or act upon the selected content. You can customize which applications can trigger Quick Edit, and temporarily pause it for specific apps when needed. All text processing happens locally on your device, ensuring your data remains private."
                )
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .lineSpacing(2)
            }
            
            enable
            
            if config.isEnabled {
                if !config.excludedApps.isEmpty {
                	excludedApps
            	}
            
				if !config.pausedApps.isEmpty {
					pausedApps
				}
            
            #if DEBUG
            	trainingDataSection
            #endif
            }
        }
        .formStyle(.grouped)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshPermissionStatus()
        }
    }
    
    private var enable: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Enable Quick Edit")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $config.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    SettingInfoButton(
                        title: "Quick Edit",
                        description:
                            "When enabled, Onit displays a small indicator next to any text you highlight across applications. Press \"\(shortcutText)\" or click the indicator to instantly access Onit's AI features for that text.",
                        defaultValue: "on",
                        valueType: "Bool"
                    )
                }
                
                Text("Display quick edit anywhere")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray200)
            }
            
            if config.isEnabled {
                screenRecordingPermission
                
                KeyboardShortcuts.Recorder(
                    "Shortcut", name: .quickEdit
                ) { _ in
                    shortcutText = KeyboardShortcuts.Name.quickEdit.shortcutText
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var excludedApps: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Excluded Applications")
                    .font(.system(size: 13))
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(config.excludedApps.sorted()), id: \.self) { app in
                        HStack(alignment: .center) {
                            Text(app)
                                .font(.system(size: 12))
                            
                            Spacer()
                            
                            Button(action: {
                                config.excludedApps.remove(app)
                            }) {
                                Image(.bin)
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .frame(height: 24)
                    }
                }
            }
        }
    }

	private var screenRecordingPermission: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Screen Recording Permission")
                    .font(.system(size: 13))
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { permissionManager.isScreenRecordingEnabled },
                    set: { newValue in
                        if newValue && !permissionManager.isScreenRecordingEnabled {
                            _ = permissionManager.requestScreenRecordingPermission()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                
                SettingInfoButton(
                    title: "Screen Recording Permission",
                    description: "Required for precise hint positioning. This allows Onit to capture screenshots of selected text to accurately position the Quick Edit hint next to your selection.",
                    defaultValue: "off",
                    valueType: "Bool"
                )
            }
            
            if let messageToShow = permissionManager.messageToShow {
                Text(messageToShow)
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .transition(.opacity)
            } else {
                Text("Required for precise hint positioning. This allows Onit to capture screenshots of highlighted text to accurately position the Quick Edit hint next to your selection.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray200)
            }
        }
    }
    
    private var pausedApps: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Paused Applications")
                    .font(.system(size: 13))
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(config.pausedApps), id: \.key) { appName, pauseEndDate in
                        HStack(alignment: .center, spacing: 4) {
                            Text(appName)
                                .font(.system(size: 12))
                            Text("(until \(pauseEndDate.formatted(date: .omitted, time: .shortened)))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button(action: {
                                config.pausedApps.removeValue(forKey: appName)
                            }) {
                                Image(.bin)
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .frame(height: 24)
                    }
                }
            }
        }
    }
    
    #if DEBUG
    private var trainingDataSection: some View {
        Section {
            HighlightedTextBoundTrainingDataReviewView()
        } header: {
            Text("Training Data")
                .font(.system(size: 14))
                .padding(.vertical, 2)
            Text("Collect and review training data for model to automatically detect text bounds from screenshots.")
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .lineSpacing(2)
        }
    }
    #endif
}

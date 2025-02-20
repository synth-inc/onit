import AppKit
import Defaults
import KeyboardShortcuts
import PostHog
import SwiftUI

struct AccessibilityTab: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    var body: some View {
        Form {
            Section {

            } header: {
                Text("Auto-Context")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text(
                    "With Auto-Context, Onit can load context directly from your computer using Apple's screen-reader APIs. Auto-Context spares you the hassle of manually uploading files or copy/pasting. Data loaded with Auto-Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded."
                )
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .lineSpacing(2)

                if let demoUrl = featureFlagsManager.autocontextDemoVideoUrl {
                    Button {
                        NSWorkspace.shared.open(URL(string: demoUrl)!)
                    } label: {
                        HStack(spacing: 6) {
                            Image(.playButton)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text("Watch the demo")
                                .font(.system(size: 13))
                        }
                        .padding(.vertical, 6)
                    }
                    .background(Color(.blue))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Enable Auto-Context")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { featureFlagsManager.accessibility },
                                set: { featureFlagsManager.overrideAccessibility($0) }
                            )
                        )
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    Text("You'll need to grant Accessibility access.")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                }
            }

            if featureFlagsManager.accessibility {
                HighlightedTextSection()

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Current Window Shortcut")
                                .font(.system(size: 13))
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: {
                                        featureFlagsManager.accessibilityAutoContext
                                    },
                                    set: {
                                        featureFlagsManager.overrideAccessibilityAutoContext($0)
                                    }
                                )
                            )
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            SettingInfoButton(
                                title: "Auto-Context, Screen Reader Shortcut",
                                description:
                                    "When enabled, Onit adds a shortcut that, when triggered, will read the text from the foregrounded application and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.",
                                defaultValue: "on",
                                valueType: "Bool"
                            )
                        }
                        Text("Loads context from the active window")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray200)
                    }
                    KeyboardShortcuts.Recorder(
                        "Shortcut", name: .launchWithAutoContext
                    )
                }
                
                TypeAheadSection()
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    ModelContainerPreview {
        AccessibilityTab()
    }
}

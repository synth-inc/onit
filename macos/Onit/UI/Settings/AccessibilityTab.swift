import Defaults
import KeyboardShortcuts
import PostHog
import SwiftUI
import KeyboardShortcuts
import AppKit

struct AccessibilityTab: View {
    @Default(.autoContextFromHighlights) var autoContextFromHighlights
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.automaticallyAddAutoContext) var automaticallyAddAutoContext

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    var autoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    var body: some View {
        Form {
            Section {

            } header: {
                Text("AutoContext")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text(
                    "With AutoContext, Onit can load context directly from your computer using Apple's screen reader APIs. AutoContext spares you the hassle of manually uploading files or copy/pasting. Data loaded with AutoContext is not uploaded until you submit your conversation. In local mode, no context is ever uploaded."
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
                        Text("Accessibility enabled")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { autoContextEnabled },
                                set: { _ in
                                    if let url = URL(string: MenuCheckForPermissions.link) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            )
                        )
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    Text("Required for automatic context loading, text insertion, window resizing, and many other Onit features.")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                }
            }

            if autoContextEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Highlighted Text")
                                .font(.system(size: 13))
                            Spacer()
                            Toggle("", isOn: $autoContextFromHighlights)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            SettingInfoButton(
                                title: "AutoContext from Highlighted Text",
                                description:
                                    "When enabled, Onit will read highlighted text from any application, and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.",
                                defaultValue: "on",
                                valueType: "Bool"
                            )
                        }
                        Text("Automatically loads highlighted text as content.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray200)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Current Window (Experimental)")
                                .font(.system(size: 13))
                            Spacer()
                            Toggle("", isOn: $autoContextFromCurrentWindow)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            SettingInfoButton(
                                title: "AutoContext, Screen Reader Shortcut (Experimental)",
                                description:
                                    "When enabled, Onit adds a shortcut that, when triggered, will read the text from the foregrounded application and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.",
                                defaultValue: "on",
                                valueType: "Bool"
                            )
                        }
                        Text("Loads context from the active window. Warning: If you notice the application freeze after enabling this, please disable it.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray200)
                    }
                    if !featureFlagsManager.usePinnedMode {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Automatically Read Current Window")
                                    .font(.system(size: 13))
                                Spacer()
                                Toggle(
                                    "",
                                    isOn: Binding(
                                        get: { automaticallyAddAutoContext },
                                        set: { automaticallyAddAutoContext = $0 }
                                    )
                                )
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }
                            Text("When enabled, Onit will automatically capture context from the active window. Please use this feature cautiously, as sensitive information may be unintentionally uploaded.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray200)
                            if !automaticallyAddAutoContext {
                                KeyboardShortcuts.Recorder(
                                    "Shortcut", name: .launchWithAutoContext
                                )
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Automatically Read Current Window")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray300)
                            Text("This feature is not available in Pinned mode.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray200)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

//#Preview {
//    ModelContainerPreview {
//        AccessibilityTab()
//    }
//}

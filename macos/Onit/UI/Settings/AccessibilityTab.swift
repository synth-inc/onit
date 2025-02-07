import PostHog
import SwiftUI
import KeyboardShortcuts
import AppKit

struct AccessibilityTab: View {
    
    struct HighlightHintModeUI: Identifiable, Hashable, Equatable {
        let mode: HighlightHintMode
        let text: String
        
        var id: String { text }
        
        static func from(mode: HighlightHintMode) -> Self {
            let text: String
            
            switch mode {
            case .topRight:
                text = "Top-right corner of the screen"
            case .textfield:
                text = "Above the highlighted text"
            case .none:
                text = "No hint"
            }
            
            return .init(mode: mode, text: text)
        }
        
        static func == (lhs: HighlightHintModeUI, rhs: HighlightHintModeUI) -> Bool {
            return lhs.mode == rhs.mode
        }
    }
    
    private let modes: [HighlightHintModeUI] = [
        HighlightHintModeUI.from(mode: .none),
        HighlightHintModeUI.from(mode: .topRight)
//        HighlightHintModeUI.from(mode: .textfield)
    ]
    
    @Environment(\.model) var model
    
    @State private var selectedMode: HighlightHintModeUI = HighlightHintModeUI.from(mode: FeatureFlagManager.shared.highlightHintMode)
    
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    var body: some View {
        Form {
            Section {
                
            } header: {
                Text("Auto-Context")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text("With Auto-Context, Onit can load context directly from your computer using Apple's screen-reader APIs. Auto-Context spares you the hassle of manually uploading files or copy/pasting. Data loaded with Auto-Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.")
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
                        Toggle("", isOn: Binding(
                            get: { featureFlagsManager.accessibility },
                            set: { featureFlagsManager.overrideAccessibility($0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    Text("You'll need to grant Accessibility access.")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                }
            }
            
            if featureFlagsManager.accessibility {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Highlighted Text")
                                .font(.system(size: 13))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { featureFlagsManager.accessibilityInput },
                                set: { featureFlagsManager.overrideAccessibilityInput($0) }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            SettingInfoButton(
                                title: "Auto-Context from Highlighted Text",
                                description: "When enabled, Onit will read highlighted text from any application, and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded." ,
                                defaultValue: "on",
                                valueType: "Bool"
                            )
                        }
                        Text("Automatically loads highlighted text as content.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray200)
                    }
                    
                    Picker("Choose hint position", selection: $selectedMode) {
                        ForEach(modes, id: \.self) { mode in
                            Text(mode.text)
                                .appFont(.medium14)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 4)
                    .tint(.blue600)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Current Window Shortcut")
                                .font(.system(size: 13))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: {
                                    featureFlagsManager.accessibilityAutoContext
                                },
                                set: { featureFlagsManager.overrideAccessibilityAutoContext($0) }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            SettingInfoButton(
                                title: "Auto-Context, Screen Reader Shortcut",
                                description: "When enabled, Onit adds a shortcut that, when triggered, will read the text from the foregrounded application and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.",
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
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: selectedMode, initial: false) { old, new in
            highlightModeChange(oldValue: old, newValue: new)
        }
    }
    
    private func highlightModeChange(oldValue: HighlightHintModeUI, newValue: HighlightHintModeUI) {
        FeatureFlagManager.shared.overrideHighlightHintMode(newValue.mode)
        HighlightHintWindowController.shared.changeMode(newValue.mode)
        
        let eventProperties: [String: Any] = [
            "old": oldValue.mode,
            "new": newValue.mode
        ]
        
        PostHogSDK.shared.capture("highlight_hint_mode_change", properties: eventProperties)
    }
}

//#Preview {
//    ModelContainerPreview {
//        AccessibilityTab()
//    }
//}

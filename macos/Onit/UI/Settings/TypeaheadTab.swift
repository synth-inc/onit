import SwiftUI
import Defaults

struct TypeaheadTab: View {
    @Default(.collectTypeaheadTestCases) var collectTypeaheadTestCases
    @ObservedObject private var debugManager = DebugManager.shared
    @ObservedObject private var windowManager = TypeaheadTestCasesWindowManager.shared
    
    var body: some View {
        Form {
            Section {
                typeaheadSettings
            } header: {
                Text("Typeahead Learning")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text(
                    "Typeahead learning analyzes your typing patterns across all applications to improve text prediction and suggestions. Enable data collection to build a local training dataset from your typing behavior."
                )
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .lineSpacing(2)
            }
            
            #if DEBUG || BETA
            Section {
                testCasesSection
            } header: {
                Text("Test Cases")
                    .font(.system(size: 14))
                    .padding(.vertical, 2)
                Text(
                    "View and manage collected typeahead test cases. These are used to train and validate the typeahead learning algorithms."
                )
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .lineSpacing(2)
            }
            #endif
        }
        .formStyle(.grouped)
    }
    
    private var typeaheadSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Collect Typeahead Test Cases")
                        .font(.system(size: 13, weight: .medium))
                    Text("Record typing patterns and text changes for machine learning training")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray200)
                }
                
                Spacer()
                
                Toggle("", isOn: $collectTypeaheadTestCases)
                    .toggleStyle(.switch)
                    .scaleEffect(0.8)
            }
            
            if collectTypeaheadTestCases {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        
                        Text("Data Collection Active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Typeahead learning is now collecting data from your typing across all applications. This data is stored locally and used to improve text prediction accuracy.")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray200)
                        .lineSpacing(2)
                }
                .padding(.leading, 20)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy & Data")
                    .font(.system(size: 13, weight: .medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("All data is stored locally on your device")
                            .font(.system(size: 11))
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("No typing data is sent to external servers")
                            .font(.system(size: 11))
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("Data is used only for improving typeahead suggestions")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(.gray200)
            }
        }
    }
    
    private var testCasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Test Cases")
                        .font(.system(size: 13, weight: .medium))
                    Text("Open a resizable window to view and manage collected test cases")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray200)
                }
                
                Spacer()
                
                Button(windowManager.isWindowOpen() ? "Window Open" : "Open Window") {
                    windowManager.showWindow()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(windowManager.isWindowOpen())
            }
            
            if windowManager.isWindowOpen() {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                    
                    Text("Test cases window is currently open")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    TypeaheadTab()
} 
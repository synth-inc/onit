import SwiftUI
import Defaults

struct WebSearchTab: View {
    @Environment(\.appState) var appState
    
    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    @Default(.tavilyCostSavingMode) var tavilyCostSavingMode
    @Default(.allowWebSearchInLocalMode) var allowWebSearchInLocalMode
    
    @State private var isValidating = false
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            OfflineText()
            
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configure web search providers to enhance your AI responses with real-time information from the internet.")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray200)
                        
                        Divider()
                        
                        tavilySection
                    }
                } header: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Web Search Providers")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        localModeSection
                    }
                } header: {
                    HStack {
                        Image(systemName: "lock.shield")
                        Text("Local Mode")
                    }
                }
            }
            .formStyle(.grouped)
            .opacity(appState.isOnline ? 1 : 0.4)
            .allowsHitTesting(appState.isOnline)
        }
        .padding()
    }
    
    var localModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Enable Web Search in Local Mode", isOn: $allowWebSearchInLocalMode)
                    .font(.system(size: 13))
            }

            Text("When enabled, web search will be available in local mode. Please note that your queries will be sent to the search provider's servers, and we cannot guarantee that your data won't be stored or logged by the provider.")
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var tavilySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tavily")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                if isTavilyAPITokenValidated {
                    Text("Connected")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text("Tavily is a powerful search API that provides real-time information from the web. Get your API key at [tavily.com](https://app.tavily.com).")
                .font(.system(size: 13))
                .foregroundStyle(.gray200)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.system(size: 13))
                
                HStack {
                    SecureField("Enter your Tavily API key", text: $tavilyAPIToken)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    
                    Button(action: validateTavilyAPIToken) {
                        if isValidating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Validate")
                        }
                    }
                    .disabled(tavilyAPIToken.isEmpty || isValidating)
                }
                
                if let error = validationError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
            }

            if isTavilyAPITokenValidated {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Cost Saving Mode", isOn: $tavilyCostSavingMode)
                            .font(.system(size: 13))
                    }

                    Text("When enabled, Onit will use your Tavily token to perform searches instead of Onit credits. By default, Onit uses model provider search tools when available for optimal quality.")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func validateTavilyAPIToken() {
        guard !tavilyAPIToken.isEmpty else { return }
        
        isValidating = true
        validationError = nil
        
        Task {
            do {
                let validated = try await TavilyService.validateAPIKey(tavilyAPIToken)
                
                await MainActor.run {
                    isValidating = false
                    isTavilyAPITokenValidated = validated
                    
                    if !validated {
                        validationError = "Invalid API key. Please check and try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    isTavilyAPITokenValidated = false
                    validationError = "Error validating API key: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    WebSearchTab()
}

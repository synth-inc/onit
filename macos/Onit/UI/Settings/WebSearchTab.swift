import SwiftUI
import Defaults

struct WebSearchTab: View {
    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    @Default(.tavilyCostSavingMode) var tavilyCostSavingMode
    @Default(.allowWebSearchInLocalMode) var allowWebSearchInLocalMode
    
    @State private var openApiKeyDropdown: Bool = false
    @State private var isValidating = false
    @State private var validationError: String? = nil
    
    var body: some View {
        Form {
            SettingsAuthCTA(
                caption: "Create an account to access all web search providers without API Keys.",
                fitContainer: true
            )
            .padding(3)
            
            SettingsSection(
                iconSystem: "magnifyingglass",
                title: "Web Search Providers"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Web search can enhance your AI responses with real-time information from the internet.")
                        .styleText(
                            size: 13,
                            color: .gray200
                        )
                    
                    Divider()
                    
                    tavilySection
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
    }
    
//  MARK: - Child Components
    
    private func connectedStatus(connected: Bool) -> some View {
        Text(connected ? "Connected" : "Using Onit Server")
            .font(.system(size: 12))
            .foregroundStyle(connected ? .green : .blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(connected ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(4)
    }
    
    private var caption: some View {
        Text("Tavily is a powerful search API that provides real-time information from the web.")
            .styleText(
                size: 13,
                color: .gray200
            )
    }
    
    private var validatedButton: some View {
        SimpleButton(
            text: "Validated",
            disabled: true,
            textColor: .black,
            background: .white
        )
    }
    
    private var removeApiKeyButton: some View {
        SimpleButton(text: "Remove") {
            tavilyAPIToken = ""
            isTavilyAPITokenValidated = false
        }
    }
    
    private var validateButton: some View {
        SimpleButton(
            text: "Validate",
            loading: isValidating,
            disabled: tavilyAPIToken.isEmpty || isValidating
        ) {
            validateTavilyAPIToken()
        }
    }
    
    private var apiKeyDropdown: some View {
        DisclosureGroup(
            "Tavily API Key\(isTavilyAPITokenValidated ? " ✅" : "")",
            isExpanded: $openApiKeyDropdown
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    SecureField("Enter API key:", text: $tavilyAPIToken)
                        .textFieldStyle(.roundedBorder)
                        .styleText(size: 13, weight: .regular)
                    
                    if isTavilyAPITokenValidated {
                        validatedButton
                        removeApiKeyButton
                    } else {
                        validateButton
                    }
                }
                
                if let error = validationError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                
                Text("You can put in [your Tavily API key](https://app.tavily.com) to use Tavily web search at cost.")
                    .styleText(
                        size: 13,
                        color: .gray200
                    )
                
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
            .padding(.top, 8)
        }
    }
    
    private var tavilySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tavily")
                    .styleText(
                        size: 13,
                        weight: .semibold
                    )
                
                Spacer()
                
                connectedStatus(connected: isTavilyAPITokenValidated)
            }
            
            caption
            apiKeyDropdown
        }
    }
    
    private var localModeSection: some View {
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
    
//  MARK: - Private Functions
    
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

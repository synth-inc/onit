import SwiftUI
import Defaults

struct WebSearchTab: View {
    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    @Default(.tavilyCostSavingMode) var tavilyCostSavingMode
    @Default(.allowWebSearchInLocalMode) var allowWebSearchInLocalMode
    
    @State private var isValidating = false
    @State private var validationError: String? = nil
    @State private var showApiKey: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsAuthCTA(
                    caption: "Create an account to access all web search providers without API Keys."
                )
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Web Search Providers")
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Web search can enhance your AI responses with real-time information from the internet.")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray200)
                        
                        Divider()
                        
                        tavilySection
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
                
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Local Mode")
                }
                
                localModeSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
            .padding(.horizontal, 54)
        }
    }
    
    var localModeSection: some View {
        GroupBox {
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
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var textField: some View {
        HStack(alignment: .center, spacing: 8) {
            SecureField("Enter your Tavily API key", text: $tavilyAPIToken)
                .textFieldStyle(PlainTextFieldStyle())
                .styleText(size: 13, weight: .regular)
                .padding(0)
                .padding(.vertical, 4)
                .padding(.horizontal, 7)
                .background(.systemGray900)
                .addBorder(cornerRadius: 5, stroke: .systemGray800)
            
            SimpleButton(
                isLoading: isValidating,
                disabled: isTavilyAPITokenValidated || tavilyAPIToken.isEmpty || isValidating,
                text: isValidating ? "Validating" : isTavilyAPITokenValidated ? "Validated" : "Validate",
                textColor: isTavilyAPITokenValidated ? .black : .white,
                action: validateTavilyAPIToken
            )
            
            if isTavilyAPITokenValidated {
                SimpleButton(
                    text: "Remove",
                    action: {
                        isTavilyAPITokenValidated = false
                        tavilyAPIToken = ""
                    }
                )
            }
        }
    }
    
    var tavilySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Tavily")
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Text(isTavilyAPITokenValidated ? "Connected" : "Not Connected")
                    .font(.system(size: 12))
                    .fontWeight(.medium)
                    .foregroundStyle(isTavilyAPITokenValidated ? .green : .gray100)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(isTavilyAPITokenValidated ? Color.green.opacity(0.2) : Color.gray200.opacity(0.2))
                    .cornerRadius(4)
                    .opacity(isTavilyAPITokenValidated ? 1 : 0.5)
            }
            
            Text("Tavily is a powerful search API that provides real-time information from the web.")
                .font(.system(size: 13))
                .foregroundStyle(.gray200)
            
            DisclosureGroup("Tavily API Key\(isTavilyAPITokenValidated ? " ✅" : "")", isExpanded: $showApiKey) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 16) {
                        Text("Enter API key:")
                            .styleText(size: 12, weight: .regular)
                        
                        textField
                    }
                    
                    if let error = validationError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    
                    Text("You can put in [your Tavily API key](https://app.tavily.com) to use Tavily web search at cost.")
                        .styleText(size: 12, weight: .regular)
                }
                .padding(.top, 10)
            }
            .styleText(size: 12, weight: .regular)

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

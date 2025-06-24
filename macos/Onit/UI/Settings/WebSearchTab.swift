import SwiftUI
import Defaults

struct WebSearchTab: View {
    @Default(.webSearchEnabled) var webSearchEnabled
    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    
    @State private var isValidating = false
    @State private var validationError: String? = nil
    
    var body: some View {
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
        }
        .formStyle(.grouped)
        .padding()
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
                } else {
                    Text("Using Onit Server")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
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
                        webSearchEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    isTavilyAPITokenValidated = false
                    webSearchEnabled = false
                    validationError = "Error validating API key: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    WebSearchTab()
}

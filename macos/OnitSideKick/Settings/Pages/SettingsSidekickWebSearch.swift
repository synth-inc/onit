//
//  SettingsSidekickWebSearch.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import Defaults
import SwiftUI

struct SettingsSidekickWebSearch: View {
    // MARK: - Defaults

    @Default(.tavilyAPIToken) private var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) private var isTavilyAPITokenValidated
    @Default(.tavilyCostSavingMode) private var tavilyCostSavingMode
    @Default(.allowWebSearchInLocalMode) private var allowWebSearchInLocalMode

    // MARK: - Observed Objects

    @ObservedObject private var localizationManager = LocalizationManager.shared

    // MARK: - States

    @State private var isValidating = false
    @State private var validationError: String? = nil
    @State private var showApiKey: Bool = false

    // MARK: - Body

    var body: some View {
        SettingsAuthCTA(
            caption: String.localized("Create an account to access all web search providers without API Keys.", table: "Sidekick")
        )

        webSearchProvidersSection
        localModeSection
    }

    // MARK: - Child Components: Web Search Providers Section

    private var webSearchProvidersSection: some View {
        SettingsPageSection(
            title: .init(text: String.localized("Web Search Providers", table: "Sidekick")),
            subtitle: .init(text: String.localized("Web search can enhance your AI responses with real-time information from the internet.", table: "Sidekick"))
        ) {
            tavilySection
            
            if isTavilyAPITokenValidated {
                DividerHorizontal()
                costSavingModeToggle
            }
        }
    }

    private var tavilySection: some View {
        SettingsPageSubsection {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("Tavily")
                        .styleText(
                            size: 13,
                            weight: .semibold
                        )

                    Spacer()

                    connectionStatusBadge
                }

                Text(String.localized("Tavily is a powerful search API that provides real-time information from the web.", table: "Sidekick"))
                    .styleText(
                        size: 12,
                        color: Color.S_2
                    )

                apiKeyDisclosure
            }
        }
    }

    private var connectionStatusBadge: some View {
        Text(isTavilyAPITokenValidated ? String.localized("Connected", table: "Sidekick") : String.localized("Not Connected", table: "Sidekick"))
            .styleText(
                size: 12,
                weight: .medium,
                color: isTavilyAPITokenValidated ? Color.green : Color.S_1
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(isTavilyAPITokenValidated ? Color.green.opacity(0.2) : Color.S_2.opacity(0.2))
            .cornerRadius(4)
    }

    private var apiKeyDisclosure: some View {
        DisclosureGroup(
            isTavilyAPITokenValidated ? String.localized("Tavily API Key", table: "Sidekick") + " ✅" : String.localized("Tavily API Key", table: "Sidekick"),
            isExpanded: $showApiKey
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 16) {
                    Text(String.localized("Enter API key:", table: "Sidekick"))
                        .styleText(size: 12)

                    apiKeyTextField
                }

                if let error = validationError {
                    Text(error)
                        .styleText(size: 12, color: Color.red500)
                }

                tavilyApiKeyCaption
            }
            .padding(.top, 10)
        }
        .styleText(size: 12)
    }

    private var tavilyApiKeyLink: String {
        "[\(String.localized("your Tavily API key", table: "Sidekick"))](https://app.tavily.com)"
    }

    private var tavilyApiKeyCaption: some View {
        (Text(String.localized("You can put in ", table: "Sidekick"))
            + Text(.init(tavilyApiKeyLink))
            + Text(String.localized(" to use Tavily web search at cost.", table: "Sidekick")))
            .styleText(size: 12)
    }

    private var apiKeyTextField: some View {
        HStack(alignment: .center, spacing: 8) {
            SecureField(String.localized("Enter your Tavily API key", table: "Sidekick"), text: $tavilyAPIToken)
                .textFieldStyle(PlainTextFieldStyle())
                .styleText(size: 13)
                .padding(.vertical, 4)
                .padding(.horizontal, 7)
                .background(Color.T_8)
                .addBorder(cornerRadius: 5, stroke: Color.genericBorder)

            SimpleButton(
                isLoading: isValidating,
                disabled: isTavilyAPITokenValidated || tavilyAPIToken.isEmpty || isValidating,
                text: isValidating ? String.localized("Validating", table: "Sidekick") : isTavilyAPITokenValidated ? String.localized("Validated", table: "Sidekick") : String.localized("Validate", table: "Sidekick"),
                textColor: isTavilyAPITokenValidated ? Color.black : Color.white,
                action: validateTavilyAPIToken,
                background: isTavilyAPITokenValidated ? Color.S_4 : Color.blue
            )

            if isTavilyAPITokenValidated {
                SimpleButton(
                    text: String.localized("Remove", table: "Sidekick"),
                    action: {
                        isTavilyAPITokenValidated = false
                        tavilyAPIToken = ""
                    }
                )
            }
        }
    }

    private var costSavingModeToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Cost Saving Mode", table: "Sidekick"),
                subtitle: String.localized("When enabled, Onit will use your Tavily token to perform searches instead of Onit credits. By default, Onit uses model provider search tools when available for optimal quality.", table: "Sidekick")
            ),
            isOn: self.$tavilyCostSavingMode
        )
    }
    
    // MARK: - Child Components: Local Mode Section

    private var localModeSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Local Mode", table: "Sidekick"))) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Enable Web Search in Local Mode", table: "Sidekick"),
                    subtitle: String.localized("When enabled, web search will be available in local mode. Please note that your queries will be sent to the search provider's servers, and we cannot guarantee that your data won't be stored or logged by the provider.", table: "Sidekick")
                ),
                isOn: self.$allowWebSearchInLocalMode
            )
        }
    }

    // MARK: - Private Functions

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
                        validationError = String.localized("Invalid API key. Please check and try again.", table: "Sidekick")
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    isTavilyAPITokenValidated = false
                    validationError = String(format: String.localized("Error validating API key: %@", table: "Sidekick"), error.localizedDescription)
                }
            }
        }
    }
}

//
//  AppState.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import Defaults
import DefaultsMacros
import Sparkle
import SwiftUI

@MainActor
@Observable
class AppState: NSObject {
    
    // MARK: - Properties
    
    var settingsTab: SettingsTab = .models
    var showMenuBarExtra: Bool = false
    var updater = SPUStandardUpdaterController(startingUpdater: true,
                                               updaterDelegate: nil,
                                               userDriverDelegate: nil)
    
    var remoteFetchFailed: Bool = false
    var localFetchFailed: Bool = false
    
    var account: Account? {
        didSet {
            if account == nil {
                fetchSubscriptionTask?.cancel()
                fetchSubscriptionTask = nil
                subscription = nil
            } else {
                fetchSubscriptionTask?.cancel()
                fetchSubscriptionTask = Task {
                    subscription = try? await FetchingClient().getSubscription()
                }
            }
        }
    }
    private var fetchSubscriptionTask: Task<Void, Never>?
    
    var subscription: Subscription? {
        didSet {
            if subscriptionActive {
                return
            }
            // If they don't have a subscription and don't have a key for their current remote model, set to nil
            invalidateRemoteModel()
            Defaults[.useOnitChat] = false
        }
    }
    var subscriptionActive: Bool { subscription?.status == "active" || subscription?.status == "trialing" }
    
    var subscriptionStatus: String? {
        if account != nil && subscription == nil {
            return SubscriptionStatus.free
        } else if let subscription = subscription {
            switch subscription.status {
            case "canceled":
                return SubscriptionStatus.canceled
            case "trialing":
                return SubscriptionStatus.trialing
            case "active":
                return SubscriptionStatus.active
            default:
                // Stripe statuses: Incomplete, Incomplete Expired, Past Due, Unpaid, and Paused
                return SubscriptionStatus.free
            }
        } else {
            return nil
        }
    }
    
    var showFreeLimitAlert: Bool = false
    var showProLimitAlert: Bool = false
    var subscriptionPlanError: String = ""

    // MARK: - Initializer
    
    override init() {
        super.init()

        Task {
            await fetchLocalModels()
            await fetchRemoteModels()

            // This handles an edge case where Ollama is running but there is no internet connection
            // We put the user in localmode so they can use the product.
            // We don't do the opposite, because we don't want to put the product in remote mode without them knowing.
            if !Defaults[.availableLocalModels].isEmpty && Defaults[.availableRemoteModels].isEmpty
            {
                Defaults[.mode] = .local
            }
        }
    }
    
    // MARK: - Functions
    
    func setSettingsTab(tab: SettingsTab) {
        settingsTab = tab
    }
    
    @MainActor
    func fetchLocalModels() async {
        do {
            let models = try await FetchingClient().getLocalModels()

            // Handle local model selection
            let localModel = Defaults[.localModel]

            Defaults[.availableLocalModels] = models
            if models.isEmpty {
                Defaults[.localModel] = nil
            } else if localModel == nil || !models.contains(localModel!) {
                Defaults[.localModel] = models[0]
            }
            if listedModels.isEmpty {
                Defaults[.mode] = .local
            }
            localFetchFailed = false

            // Reset the closedNoLocalModels flag when local models are successfully fetched.
            Defaults[.closedNoLocalModels] = false
        } catch {
            print("Error fetching local models:", error)
            localFetchFailed = true
            Defaults[.availableLocalModels] = []
            Defaults[.localModel] = nil
        }
    }

    @MainActor
    func fetchRemoteModels() async {
        do {
            var models = try await AIModel.fetchModels()

            // This means we've never successfully fetched before
            if Defaults[.availableRemoteModels].isEmpty {
                if Defaults[.visibleModelIds].isEmpty {
                    Defaults[.visibleModelIds] = Set(
                        models.filter { $0.defaultOn }.map { $0.uniqueId })
                }

                Defaults[.availableRemoteModels] = models
                if !listedModels.isEmpty {
                    Defaults[.remoteModel] = listedModels.first
                }
            } else {

                // Migrate legacy model IDs if needed
                if !Defaults[.hasPerformedModelIdMigration] {
                    let legacyIds = Defaults[.visibleModelIds]
                    let migratedIds = AIModel.migrateVisibleModelIds(
                        models: Defaults[.availableRemoteModels], legacyIds: legacyIds)
                    Defaults[.visibleModelIds] = migratedIds
                    Defaults[.hasPerformedModelIdMigration] = true
                }

                // Update the availableRemoteModels with the newly fetched models
                let newModelIds = Set(models.map { $0.id })
                let existingModelIds = Set(Defaults[.availableRemoteModels].map { $0.id })

                let newModels = models.filter { !existingModelIds.contains($0.id) }
                var deprecatedModels = Defaults[.availableRemoteModels].filter {
                    !newModelIds.contains($0.id)
                }
                for index in models.indices where newModels.contains(models[index]) {
                    models[index].isNew = true
                }

                for index in deprecatedModels.indices {
                    deprecatedModels[index].isDeprecated = true
                }

                // We only save deprecated models if the user has them visibile. Otherwise, quietly remove them from the list.
                let visibleModelIds = Set(Defaults[.visibleModelIds])
                let visibleDeprecatedModels = deprecatedModels.filter {
                    visibleModelIds.contains($0.uniqueId)
                }

                remoteFetchFailed = false
                Defaults[.availableRemoteModels] = models + visibleDeprecatedModels
                if visibleModelIds.isEmpty {
                    Defaults[.visibleModelIds] = Set(
                        (models + visibleDeprecatedModels).filter { $0.defaultOn }.map {
                            $0.uniqueId
                        })
                }

                if !listedModels.isEmpty
                    && (Defaults[.remoteModel] == nil
                        || !Defaults[.availableRemoteModels].contains(Defaults[.remoteModel]!))
                {
                    Defaults[.remoteModel] = Defaults[.availableRemoteModels].first
                }
            }

        } catch {
            print("Error fetching remote models:", error)
            remoteFetchFailed = true
        }
    }
    
    func handleTokenLogin(_ url: URL) {
        guard url.scheme == "onit" else {
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }

        guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            print("Login token not found")
            return
        }

        Task { @MainActor in
            do {
                let loginResponse = try await FetchingClient().loginToken(loginToken: token)
                TokenManager.token = loginResponse.token
                account = loginResponse.account
            } catch {}
        }
    }
    
    // MARK: - Alert Functions
    
    func checkApiKeyExistsForCurrentModelProvider() -> Bool {
        // Allow check to be bypassed for local models.
        guard Defaults[.mode] == .remote else { return true }
        
        // Don't allow check to pass when a remote model isn't selected.
        guard let currentModel = Defaults[.remoteModel] else { return false }
        
        switch currentModel.provider {
        case .openAI:
            return isOpenAITokenValidated
        case .anthropic:
            return isAnthropicTokenValidated
        case .xAI:
            return isXAITokenValidated
        case .googleAI:
            return isGoogleAITokenValidated
        case .deepSeek:
            return isDeepSeekTokenValidated
        case .perplexity:
            return isPerplexityTokenValidated
        case .custom:
            // Custom providers don't require subscription validation.
            return true
        }
    }
    
    func checkSubscriptionAlerts(callback: @escaping () -> Void) {
        subscriptionPlanError = ""
        Defaults[.showTwoWeekProTrialEndedAlert] = false
        showFreeLimitAlert = false
        showProLimitAlert = false
        
        let providerApiKeyExists = checkApiKeyExistsForCurrentModelProvider()
        
        if account == nil {
            if !providerApiKeyExists {
                subscriptionPlanError = "Add the provider API key to send a message."
            } else {
                callback()
            }
        } else if subscriptionStatus == SubscriptionStatus.canceled {
            if !providerApiKeyExists {
                Defaults[.showTwoWeekProTrialEndedAlert] = true
            } else {
                callback()
            }
        } else {
            Task {
                do {
                    let client = FetchingClient()
                    let chatUsageResponse = try await client.getChatUsage()
                    
                    if let usage = chatUsageResponse?.usage,
                       let quota = chatUsageResponse?.quota
                    {
                        let exceededPlanLimit = usage >= quota
                        let showUpsaleAlert = exceededPlanLimit && !providerApiKeyExists
                        
                        // Pro Plan alert logic.
                        if subscriptionStatus == SubscriptionStatus.active {
                            if showUpsaleAlert {
                                showProLimitAlert = true
                            } else {
                                callback()
                            }
                        }
                        
                        // Falling back to Free Plan alert logic.
                        // Also handles the Stripe Incomplete, Incomplete Expired, Past Due, Unpaid, and Paused statuses.
                        else {
                            if let subscriptionStatusMessage = subscription?.statusMessage {
                                subscriptionPlanError = subscriptionStatusMessage
                            }
                            
                            if showUpsaleAlert {
                                showFreeLimitAlert = true
                            } else {
                                callback()
                            }
                        }
                    } else {
                        // Stripe endpoint didn't return plan usage and quota. Sending another request should refresh this.
                        // If problem persists, there might be something wrong with the Stripe API.
                        subscriptionPlanError = "Please try again."
                    }
                } catch {
                    subscriptionPlanError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Remote Models

    @ObservableDefault(.availableRemoteModels)
    @ObservationIgnored
    var availableRemoteModels: [AIModel]

    @ObservableDefault(.availableCustomProviders)
    @ObservationIgnored
    var availableCustomProvider: [CustomProvider]

    @ObservableDefault(.isOpenAITokenValidated)
    @ObservationIgnored
    var isOpenAITokenValidated: Bool

    @ObservableDefault(.useOpenAI)
    @ObservationIgnored
    var useOpenAI: Bool

    @ObservableDefault(.isAnthropicTokenValidated)
    @ObservationIgnored
    var isAnthropicTokenValidated: Bool

    @ObservableDefault(.useAnthropic)
    @ObservationIgnored
    var useAnthropic: Bool

    @ObservableDefault(.isXAITokenValidated)
    @ObservationIgnored
    var isXAITokenValidated: Bool

    @ObservableDefault(.useXAI)
    @ObservationIgnored
    var useXAI: Bool

    @ObservableDefault(.isGoogleAITokenValidated)
    @ObservationIgnored
    var isGoogleAITokenValidated: Bool

    @ObservableDefault(.useGoogleAI)
    @ObservationIgnored
    var useGoogleAI: Bool

    @ObservableDefault(.isDeepSeekTokenValidated)
    @ObservationIgnored
    var isDeepSeekTokenValidated: Bool

    @ObservableDefault(.useDeepSeek)
    @ObservationIgnored
    var useDeepSeek: Bool

    @ObservableDefault(.isPerplexityTokenValidated)
    @ObservationIgnored
    var isPerplexityTokenValidated: Bool

    @ObservableDefault(.usePerplexity)
    @ObservationIgnored
    var usePerplexity: Bool

    var listedModels: [AIModel] {
        var models = availableRemoteModels.filter {
            Defaults[.visibleModelIds].contains($0.uniqueId)
        }

        if !useOpenAI || (!subscriptionActive && !isOpenAITokenValidated) {
            models = models.filter { $0.provider != .openAI }
        }
        if !useAnthropic || (!subscriptionActive && !isAnthropicTokenValidated) {
            models = models.filter { $0.provider != .anthropic }
        }
        if !useXAI || (!subscriptionActive && !isXAITokenValidated) {
            models = models.filter { $0.provider != .xAI }
        }
        if !useGoogleAI || (!subscriptionActive && !isGoogleAITokenValidated) {
            models = models.filter { $0.provider != .googleAI }
        }
        if !useDeepSeek || (!subscriptionActive && !isDeepSeekTokenValidated) {
            models = models.filter { $0.provider != .deepSeek }
        }
        if !usePerplexity || (!subscriptionActive && !isPerplexityTokenValidated) {
            models = models.filter { $0.provider != .perplexity }
        }

        // Filter out models from disabled custom providers
        for customProvider in availableCustomProvider {
            models = models.filter { model in
                if model.customProviderName == customProvider.name {
                    return customProvider.isEnabled
                }
                return true
            }
        }

        return models
    }

    var remoteNeedsSetup: Bool {
        listedModels.isEmpty
    }

    func invalidateRemoteModel() {
        guard let provider = Defaults[.remoteModel]?.provider else { return }

        var isValid: Bool

        switch provider {
        case .openAI:
            isValid = isOpenAITokenValidated
        case .anthropic:
            isValid = isAnthropicTokenValidated
        case .xAI:
            isValid = isXAITokenValidated
        case .googleAI:
            isValid = isGoogleAITokenValidated
        case .deepSeek:
            isValid = isDeepSeekTokenValidated
        case .perplexity:
            isValid = isPerplexityTokenValidated
        case .custom:
            isValid = true
        }

        if !isValid {
            Defaults[.remoteModel] = nil
        }
    }
}

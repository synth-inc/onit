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
    private var chatGenerationLimitTask: Task<Void, Never>? = nil
    
    var subscription: Subscription?
    var subscriptionActive: Bool { subscription?.status == "active" || subscription?.status == "trialing" }
    
    var subscriptionCanceled: Bool {
        if let canceled = subscription?.cancelAtPeriodEnd {
            return canceled
        } else {
            return false
        }
    }
    
    var subscriptionStatus: String? {
        if account != nil && subscription == nil {
            return SubscriptionStatus.free
        } else if let subscription = subscription {
            switch subscription.status {
            case "trialing":
                return SubscriptionStatus.trialing
            case "active":
                return SubscriptionStatus.active
            default:
                // Stripe statuses: Canceled, Incomplete, Incomplete Expired, Past Due, Unpaid, and Paused
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

                if loginResponse.isNewAccount {
                    useOpenAI = true
                    useAnthropic = true
                    useXAI = true
                    useGoogleAI = true
                    useDeepSeek = true
                    usePerplexity = true
                }
            } catch {
                print("Login by token failed with error: \(error)")
            }
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
            if Defaults[.openAIToken] != nil {
                return isOpenAITokenValidated
            } else {
                return false
            }
        case .anthropic:
            if Defaults[.anthropicToken] != nil {
                return isAnthropicTokenValidated
            } else {
                return false
            }
        case .xAI:
            if Defaults[.xAIToken] != nil {
                return isXAITokenValidated
            } else {
                return false
            }
        case .googleAI:
            if Defaults[.googleAIToken] != nil {
                return isGoogleAITokenValidated
            } else {
                return false
            }
        case .deepSeek:
            if Defaults[.deepSeekToken] != nil {
                return isDeepSeekTokenValidated
            } else {
                return false
            }
        case .perplexity:
            if Defaults[.perplexityToken] != nil {
                return isPerplexityTokenValidated
            } else {
                return false
            }
        case .custom:
            // Custom providers don't require subscription validation.
            return true
        }
    }
    
    func checkChatGenerationLimit(_ callback: @escaping () -> Void) async {
        do {
            let client = FetchingClient()
            let chatUsageResponse = try await client.getChatUsage()
            
            if let usage = chatUsageResponse?.usage,
               let quota = chatUsageResponse?.quota
            {
                let exceededPlanLimit = usage >= quota
                
                // Pro Plan alert logic.
                if subscriptionStatus == SubscriptionStatus.active {
                    if exceededPlanLimit {
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
                    
                    if exceededPlanLimit {
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
    
    func checkSubscriptionAlerts(callback: @escaping () -> Void) async {
        subscriptionPlanError = ""
        Defaults[.showTwoWeekProTrialEndedAlert] = false
        showFreeLimitAlert = false
        showProLimitAlert = false
        
        let providerApiKeyExists = checkApiKeyExistsForCurrentModelProvider()
        
        // If the user is logged out...
        //   Prevent the user from sending any messages or updating any past prompts
        //   if they haven't provided an API key for the current model.
        if account == nil {
            if !providerApiKeyExists {
                subscriptionPlanError = "Add the provider API key to send a message."
            } else {
                callback()
            }
        }
        // Otherwise, if the user is logged in...
        //   Check the user's plan's generation limit and show relevant alert if
        //     they haven't provided a valid provider API key for their currently-selected model.
        //   Otherwise, let them send messages or update past prompts as much as they want.
        else {
            if !providerApiKeyExists {
                chatGenerationLimitTask?.cancel()
                
                chatGenerationLimitTask = Task {
                    await checkChatGenerationLimit(callback)
                    chatGenerationLimitTask = nil
                }
            } else {
                callback()
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
        
        if !useOpenAI {
            models = models.filter { $0.provider != .openAI }
        }
        if !useAnthropic {
            models = models.filter { $0.provider != .anthropic }
        }
        if !useXAI {
            models = models.filter { $0.provider != .xAI }
        }
        if !useGoogleAI {
            models = models.filter { $0.provider != .googleAI }
        }
        if !useDeepSeek {
            models = models.filter { $0.provider != .deepSeek }
        }
        if !usePerplexity {
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
}

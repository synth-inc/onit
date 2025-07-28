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
class AppState: NSObject, SPUUpdaterDelegate {
    
    private var modelProvidersManager = ModelProvidersManager.shared
    
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
    
    var userLoggedIn: Bool {
        account != nil
    }
    
    var subscription: Subscription?
//    var subscriptionActive: Bool { subscription?.status == "active" || subscription?.status == "trialing" }
    
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
        
        // Used for showing/removing update available footer notification.
        updater = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )

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
            
            // Initialize visible local models if empty (first time or after being cleared)
            if Defaults[.visibleLocalModels].isEmpty && !models.isEmpty {
                Defaults[.visibleLocalModels] = Set(models)
            } else {
                // Update visible models to only include currently available models
                let currentVisible = Defaults[.visibleLocalModels]
                Defaults[.visibleLocalModels] = currentVisible.intersection(Set(models))
            }
            
            if models.isEmpty {
                Defaults[.localModel] = nil
            } else if localModel == nil || !models.contains(localModel!) {
                // Choose from visible models if available
                let visibleModels = Defaults[.visibleLocalModels]
                if let firstVisibleModel = visibleModels.first {
                    Defaults[.localModel] = firstVisibleModel
                }
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
            
            /// Removing user-removed remote models from fetched result.
            let userRemovedRemoteModelUniqueIds = Set(Defaults[.userRemovedRemoteModels].map { $0.uniqueId })
            models.removeAll { userRemovedRemoteModelUniqueIds.contains($0.uniqueId) }
            
            /// Updating fetched remote models with user-added remote models.
            for userAddedRemoteModel in Defaults[.userAddedRemoteModels] {
                if let existingModelIndex = models.firstIndex(where: { $0.uniqueId == userAddedRemoteModel.uniqueId }) {
                    models[existingModelIndex] = userAddedRemoteModel
                } else {
                    models.append(userAddedRemoteModel)
                }
            }

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
    
    func handleDeeplink(_ url: URL) {
        guard url.scheme == "onit" else {
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL: \(url)")
            return
        }
        
        // Handle different deeplink actions based on path
        switch components.path {
        case "/update", "/check-for-updates":
            handleUpdateDeeplink()
        default:
            // For backwards compatibility, if no path is specified, assume it's a token login
            handleTokenLogin(url)
            
        }
    }
    
    func handleTokenLogin(_ url: URL) {
        guard url.scheme == "onit" else {
            return
        }
        
        let provider = "email"
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            let errorMsg = "Invalid URL"
            
            AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
            print(errorMsg)
            return
        }

        guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            let errorMsg = "Login token not found"
            
            AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
            print(errorMsg)
            return
        }

        Task { @MainActor in
            do {
                let loginResponse = try await FetchingClient().loginToken(loginToken: token)

                AnalyticsManager.Auth.success(provider: provider)
                TokenManager.token = loginResponse.token
                account = loginResponse.account

                if loginResponse.isNewAccount {
                    AnalyticsManager.Identity.identify(account: loginResponse.account)
                    modelProvidersManager.useOpenAI = true
                    modelProvidersManager.useAnthropic = true
                    modelProvidersManager.useXAI = true
                    modelProvidersManager.useGoogleAI = true
                    modelProvidersManager.useDeepSeek = true
                    modelProvidersManager.usePerplexity = true
                }
            } catch {
                AnalyticsManager.Auth.failed(provider: provider, error: error.localizedDescription)
                print("Login by token failed with error: \(error)")
            }
        }
    }
    
    func handleUpdateDeeplink() {
        // Activate the app to bring it to the foreground
        NSApp.activate(ignoringOtherApps: true)
        checkForAvailableUpdateWithDownload()
    }
    
    // MARK: - Alert Functions
    
    func checkApiKeyExistsForCurrentModelProvider() -> Bool {
        // Allow check to be bypassed for local models.
        guard Defaults[.mode] == .remote else { return true }
        
        // Don't allow check to pass when a remote model isn't selected.
        guard let currentModel = Defaults[.remoteModel] else { return false }
        
        // Custom providers don't require subscription validation.
        if currentModel.provider == .custom {
            return true
        } else {
            return AIModel.ModelProvider.hasValidRemoteToken(provider: currentModel.provider)
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
    
    var listedModels: [AIModel] {
        var models = availableRemoteModels.filter {
            Defaults[.visibleModelIds].contains($0.uniqueId)
        }
        
        let cannotAccessOpenAI = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .openAI)
        let cannotAccessAnthropic = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .anthropic)
        let cannotAccessXAI = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .xAI)
        let cannotAccessGoogleAI = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .googleAI)
        let cannotAccessDeepSeek = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .deepSeek)
        let cannotAccessPerplexity = !userLoggedIn && !AIModel.ModelProvider.hasValidRemoteToken(provider: .perplexity)
        
        if cannotAccessOpenAI || !modelProvidersManager.useOpenAI {
            models = models.filter { $0.provider != .openAI }
        }
        
        if cannotAccessAnthropic || !modelProvidersManager.useAnthropic {
            models = models.filter { $0.provider != .anthropic }
        }
        
        if cannotAccessXAI || !modelProvidersManager.useXAI {
            models = models.filter { $0.provider != .xAI }
        }
        
        if cannotAccessGoogleAI || !modelProvidersManager.useGoogleAI {
            models = models.filter { $0.provider != .googleAI }
        }
        
        if cannotAccessDeepSeek || !modelProvidersManager.useDeepSeek {
            models = models.filter { $0.provider != .deepSeek }
        }
        
        if cannotAccessPerplexity || !modelProvidersManager.usePerplexity {
            models = models.filter { $0.provider != .perplexity }
        }

        // Filter out models from disabled custom providers
        for customProvider in modelProvidersManager.availableCustomProvider {
            models = models.filter { model in
                if model.customProviderName == customProvider.name {
                    return customProvider.isEnabled
                }
                return true
            }
        }

        return models
    }

//    var remoteNeedsSetup: Bool {
//        listedModels.isEmpty
//    }
    
    private func resetCurrentRemoteModel() {
        if let currentModel = Defaults[.remoteModel],
           !availableRemoteModels.contains(currentModel)
        {
            if listedModels.isEmpty {
                Defaults[.remoteModel] = nil
                Defaults[.mode] = .local
            } else {
                Defaults[.remoteModel] = listedModels.first
            }
        }
    }
    
    func removeRemoteModels(_ remoteModelsToRemove: [AIModel]) {
        /// Updating the list of user-removed remote models.
        var updatedUserRemovedRemoteModels = Defaults[.userRemovedRemoteModels]
        let userRemovedRemoteModelUniqueIds = Set(Defaults[.userRemovedRemoteModels].map { $0.uniqueId })
        
        for remoteModel in remoteModelsToRemove {
            if !userRemovedRemoteModelUniqueIds.contains(remoteModel.uniqueId) {
                updatedUserRemovedRemoteModels.append(remoteModel)
            }
        }
        
        Defaults[.userRemovedRemoteModels] = updatedUserRemovedRemoteModels
        
        /// Actions for removing remote models.
        let remoteModelsToRemoveUniqueIds = Set(remoteModelsToRemove.map { $0.uniqueId })
        
        availableRemoteModels.removeAll { remoteModelsToRemoveUniqueIds.contains($0.uniqueId) }
        
        Defaults[.userAddedRemoteModels].removeAll { remoteModelsToRemoveUniqueIds.contains($0.uniqueId) }
        
        Defaults[.visibleModelIds].subtract(remoteModelsToRemoveUniqueIds)
        
        /// Properly setting the currently selected model in the case where the user removes the previously selected one.
        resetCurrentRemoteModel()
    }
    
    func addRemoteModel(_ remoteModel: AIModel) {
        /// Updating the list of available remote models.
        let availableRemoteModelUniqueIds = Set(availableRemoteModels.map { $0.uniqueId })
        
        if !availableRemoteModelUniqueIds.contains(remoteModel.uniqueId) {
            availableRemoteModels.append(remoteModel)
        }
        
        /// Updating the list of user-added remote models.
        var updatedUserAddedRemoteModels = Defaults[.userAddedRemoteModels]
        let userAddedRemoteModelUniqueIds = Set(Defaults[.userAddedRemoteModels].map { $0.uniqueId })
        
        if !userAddedRemoteModelUniqueIds.contains(remoteModel.uniqueId) {
            updatedUserAddedRemoteModels.append(remoteModel)
        }
        
        Defaults[.userAddedRemoteModels] = updatedUserAddedRemoteModels
        
        /// Actions for adding remote models.
        Defaults[.userRemovedRemoteModels].removeAll { $0.uniqueId == remoteModel.uniqueId }
        Defaults[.visibleModelIds].insert(remoteModel.uniqueId)
        
        AnalyticsManager.Settings.Models.remoteModelAdded(remoteModel)
    }
    private func getIsRemoteProviderOn(_ provider: AIModel.ModelProvider) -> Bool {
        switch provider {
        case .openAI:
            return useOpenAI
        case .anthropic:
            return useAnthropic
        case .xAI:
            return useXAI
        case .googleAI:
            return useGoogleAI
        case .deepSeek:
            return useDeepSeek
        case .perplexity:
            return usePerplexity
        case .custom:
            return false
        }
    }
    
    var numberRemoteProvidersInUse: Int {
        var count: Int = 0
        
        let providers: [AIModel.ModelProvider] = [.openAI, .anthropic, .xAI, .googleAI, .deepSeek, .perplexity]
        
        for provider in providers {
            if getIsRemoteProviderInUse(provider) {
                count += 1
            }
        }
        
        return count
    }
    
    func setModeAndValidRemoteModel() {
        let cannotAccessRemoteModels = listedModels.isEmpty
        
        if cannotAccessRemoteModels {
            Defaults[.remoteModel] = nil
            Defaults[.modeToggleShortcutDisabled] = true
            Defaults[.mode] = .local
            return
        } else {
            if let currentRemoteModel = Defaults[.remoteModel] {
                let isCurrentProviderInUse = modelProvidersManager.getIsRemoteProviderInUse(currentRemoteModel.provider)
                
                if !isCurrentProviderInUse || !listedModels.contains(currentRemoteModel) {
                    Defaults[.remoteModel] = listedModels.first
                }
            } else {
                Defaults[.remoteModel] = listedModels.first
            }
            
            Defaults[.modeToggleShortcutDisabled] = false
        }
    }
}

// MARK: - App Update Listeners

extension AppState {
    func removeDiscordFooterNotifications() {
        Defaults[.footerNotifications].removeAll { notification in
            if case .discord = notification {
                return true
            }
            return false
        }
    }
    
    func checkForAvailableUpdate() {
        self.updater.updater.checkForUpdateInformation()
    }
    
    func checkForAvailableUpdateWithDownload() {
        self.updater.updater.checkForUpdates()
    }
    
    private func addUpdateFooterNotification() {
        if !Defaults[.footerNotifications].contains(.update) {
            Defaults[.footerNotifications].append(.update)
        }
    }
    
    nonisolated func updater(
        _ updater: SPUUpdater,
        didFindValidUpdate item: SUAppcastItem
    ) {
        Task { @MainActor in
            addUpdateFooterNotification()
        }
    }
    
    func removeUpdateFooterNotifications() {
        Defaults[.footerNotifications].removeAll { notification in
            if case .update = notification {
                return true
            }
            return false
        }
    }
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            removeUpdateFooterNotifications()
        }
    }
}

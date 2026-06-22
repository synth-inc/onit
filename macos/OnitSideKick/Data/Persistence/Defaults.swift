//
//  Defaults.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import CoreGraphics
import Defaults
import Foundation

enum AuthFlowStatus: String, Defaults.Serializable {
    case hideAuth
    case showSignUp
    case showSignIn
}

enum FooterNotification: String, Defaults.Serializable {
    case discord
    case update
}

extension Defaults.Keys {
    
    // Remote model tokens
    static let openAIToken = Key<String?>("openAIToken", default: nil)
    static let anthropicToken = Key<String?>("anthropicToken", default: nil)
    static let xAIToken = Key<String?>("xAIToken", default: nil)
    static let googleAIToken = Key<String?>("googleAIToken", default: nil)
    static let deepSeekToken = Key<String?>("deepSeekToken", default: nil)
    static let perplexityToken = Key<String?>("perplexityToken", default: nil)
    static let cerebrasToken = Key<String?>("cerebrasToken", default: nil)
    
    // Remote model validation
    static let isOpenAITokenValidated = Key<Bool>("openAITokenValidated", default: false)
    static let isAnthropicTokenValidated = Key<Bool>("anthropicTokenValidated", default: false)
    static let isXAITokenValidated = Key<Bool>("xAITokenValidated", default: false)
    static let isGoogleAITokenValidated = Key<Bool>("googleAITokenValidated", default: false)
    static let isDeepSeekTokenValidated = Key<Bool>("deepSeekTokenValidated", default: false)
    static let isPerplexityTokenValidated = Key<Bool>("perplexityTokenValidated", default: false)
    static let isCerebrasTokenValidated = Key<Bool>("cerebrasTokenValidated", default: false)
    
    // Remote model usage
    static let useOpenAI = Key<Bool>("useOpenAI", default: true)
    static let useAnthropic = Key<Bool>("useAnthropic", default: true)
    static let useXAI = Key<Bool>("useXAI", default: true)
    static let useGoogleAI = Key<Bool>("useGoogleAI", default: true)
    static let useDeepSeek = Key<Bool>("useDeepSeek", default: true)
    static let usePerplexity = Key<Bool>("usePerplexity", default: true)
    static let useCerebras = Key<Bool>("useCerebras", default: true)
    static let useLocal = Key<Bool>("useLocalModel", default: true)
    
    static let streamResponse = Key<StreamResponseConfig>("streamResponse", default: StreamResponseConfig.default)
    
    static let modeToggleShortcutDisabled = Key<Bool>("modeToggleShortcutDisabled", default: true)

    // Dialogs closed
    static let closedLocal = Key<Bool>("closedLocal", default: false)
    static let closedNoLocalModels = Key<Bool>("closedNoLocalModels", default: false)
    static let closedNoRemoteModels = Key<Bool>("closedNoRemoteModels", default: false)
    static let closedNewRemoteData = Key<Data>("closedNewRemoteData", default: Data())
    static let closedDeprecatedRemoteData = Key<Data>("closedDeprecatedRemoteData", default: Data())
    static let closedAutoContextTag = Key<Bool>("closedAutoContextTag", default: false)
    static let closedAutoContextDialog = Key<Bool>("closedAutoContext", default: false)

    static let seenLocal = Key<Bool>("seenLocal", default: false)

    static let remoteModel = Key<AIModel?>("remoteModel", default: nil)
    static let localModel = Key<String?>("localModel", default: nil)
    static let mode = Key<InferenceMode>("mode", default: .remote)
    static let availableLocalModels = Key<[String]>("availableLocalModels", default: [])
    static let availableRemoteModels = Key<[AIModel]>("availableRemoteModels", default: [])
    static let availableCustomProviders = Key<[CustomProvider]>(
        "availableCustomProvider", default: [])
    static let userRemovedRemoteModels = Key<[AIModel]>("userRemovedRemoteModels", default: [])
    static let userAddedRemoteModels = Key<[AIModel]>("userAddedRemoteModels", default: [])

    // Stores unique model identifiers in the format "provider-id" or "customProviderName-id" for custom providers
    static let visibleModelIds = Key<Set<String>>("visibleModelIds", default: Set([]))
    static let visibleLocalModels = Key<Set<String>>("visibleLocalModels", default: Set([]))
    static let hasPerformedModelIdMigration = Key<Bool>(
        "hasPerformedModelIdMigration", default: false)

    // This migration adds the 'instruction' the response object, so it can be dynamic
    static let hasPerformedInstructionResponseMigration = Key<Bool>(
        "hasPerformedInstructionResponseMigration", default: false)
    static let needsHangingPromptCleanup = Key<Bool>(
        "needsHangingPromptCleanup", default: true)
    static let hasPerformedDatabaseMigration = Key<Bool>("hasPerformedDatabaseMigration", default: false)
    static let hasPerformedBackendMigration = Key<Bool>("hasPerformedBackendMigration", default: false)

    static let localEndpointURL = Key<URL>(
        "localEndpointURL", default: URL(string: "http://localhost:11434")!)

    // Feature flags
    static let usePinnedMode = Key<Bool?>("use_screen_mode_with_accessibility", default: nil)
    
    static let autoContextFromCurrentWindow = Key<Bool>("autoContextFromCurrentWindow", default: true)
    static let autoContextFromHighlights = Key<Bool>("autoContextFromHighlights", default: true)
    static let autoContextOnLaunchTethered = Key<Bool>("autoContextOnLaunchTethered", default: true)
    static let autoContextOnLaunchPinned = Key<Bool>("autoContextOnLaunchPinned", default: true)

    // Web search
    static let webSearchEnabled = Key<Bool>("webSearchEnabled", default: false)
    static let tavilyAPIToken = Key<String>("tavilyAPIToken", default: "")
    static let isTavilyAPITokenValidated = Key<Bool>("tavilyAPITokenValidated", default: false)
    static let tavilyCostSavingMode = Key<Bool>("tavilyCostSavingMode", default: false)
    static let allowWebSearchInLocalMode = Key<Bool>("allowWebSearchInLocalMode", default: false)

    // Window state
    static let panelWidth = Key<Double>("panelWidth", default: 400)

    // General settings
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system)
    static let launchOnStartupRequested = Key<Bool>("launchOnStartupRequested", default: false)
    static let hideDockIcon = Key<Bool>("hideDockIcon", default: false)
    static let fontSize = Key<Double>("fontSize", default: 14.0)
    static let lineHeight = Key<Double>("lineHeight", default: 1.5)
    static let voiceSilenceThreshold = Key<Float>("voiceSilenceThreshold", default: -40)
    static let voiceSpeechPassThreshold = Key<Double>("voiceSpeechPassThreshold", default: 0.7)

    // Memories
    static let memoriesEnabled = Key<Bool>("memoriesEnabled", default: true)
    static let memoryAutoDetectionEnabled = Key<Bool>("memoryAutoDetectionEnabled", default: true)
    static let maxMemoryTokens = Key<Int>("maxMemoryTokens", default: 500)

    /// Highlighted Text
    static let showHighlightedTextInput = Key<Bool>("showHighlightedTextInput", default: true)
    static let autoAddHighlightedTextToContext = Key<Bool>("autoAddHighlightedTextToContext", default: true)
    
    static let settingsPage = Key<SettingsPage>("settingsPage", default: .general)

    // Local model advanced options
    static let localKeepAlive = Key<String?>("localKeepAlive", default: nil)
    static let localNumCtx = Key<Int?>("localNumCtx", default: nil)
    static let localTemperature = Key<Double?>("localTemperature", default: nil)
    static let localTopP = Key<Double?>("localTopP", default: nil)
    static let localTopK = Key<Int?>("localTopK", default: nil)
    static let localRequestTimeout = Key<TimeInterval?>("localRequestTimeout", default: 60.0)
    
    // Debug settings
    static let launchShortcutToggleEnabled = Key<Bool>("launchShortcutToggleEnabled", default: true)
    static let createNewChatOnPanelOpen = Key<Bool>("createNewChatOnPanelOpen", default: true)
    static let escapeShortcutDisabled = Key<Bool>("escapeShortcutDisabled", default: false)
    static let openOnMouseMonitor = Key<Bool>("openOnMouseMonitor", default: false)
    
    // Onboarding
    static let showOnboardingAccessibility = Key<Bool>("showOnboardingAccessibility", default: true)
    static let authFlowStatus = Key<AuthFlowStatus>("authFlowStatus", default: .hideAuth)
    static let currentOnboardingStep = Key<OnboardingStep?>("currentOnboardingStep", default: nil)
    static let onboardingDismissed = Key<Bool>("onboardingDismissed", default: false)
    static let mainOnboardingCompleted = Key<Bool>("mainOnboardingCompleted", default: false)
    static let onboardingAuthSkipped = Key<Bool>("onboardingAuthSkipped", default: false)
    
    // Hint
    static let alwaysHideHint = Key<Bool>("alwaysHideHint", default: false)
    static let hintYPositionByApp = Key<[String: CGFloat]>("hintYPositionByApp", default: [:])
    static let hintYPositionForPinnedMode = Key<CGFloat?>("hintYPositionForPinnedMode", default: nil)
    static let hintYPositionForUntetheredModeScreens = Key<[String: CGFloat]>("hintYPositionForUntetheredModeScreens", default: [:])
    static let showHintAccessibilityAlert = Key<Bool>("showHintAccessibilityAlert", default: true)
    static let showHintUpdateAvailableAlert = Key<Bool>("showHintUpdateAvailableAlert", default: true)
    static let dismissedUpdateAlertVersion = Key<String>("dismissedUpdateAlertVersion", default: "")

    // User Info
    static let userFullName = Key<String?>("userFullName", default: nil)
    static let userCompanyName = Key<String?>("userCompanyName", default: nil)
    
    // Tethered Button Menu
    static let tetheredButtonShowAppIcons = Key<Bool>("tetheredButtonShowAppIcons", default: true)
    static let tetheredButtonHiddenApps = Key<[String: Bool]>("tetheredButtonHiddenApps", default: [:])
    static let tetheredButtonHideAllApps = Key<Bool>("tetheredButtonHideAllApps", default: false)
    static let tetheredButtonHideAllAppsTimerDate = Key<Date?>("tetheredButtonHideAllAppsTimerDate", default: nil)
    
    // Alerts
    static let showTwoWeekProTrialEndedAlert = Key<Bool>("showTwoWeekProTrialEndedAlert", default: false)
    static let hasClosedTrialEndedAlert = Key<Bool>("hasClosedTrialEndedAlert", default: false)
    
    // Notifications
    static let footerNotifications = Key<[FooterNotification]>("footerNotifications", default: [FooterNotification.discord])

    // Stop generation behavior
    static let stopMode = Key<StopMode>("stopMode", default: .removePartial)
    static let stopModeUserConfigured = Key<Bool>("stopModeUserConfigured", default: false)
    
    // OCR Comparison - BETA Only.
    // DEPRECATED: ocrComparisonResults is now stored in temp directory. This key is only kept for migration.
    static let ocrComparisonResults = Key<Data?>("ocrComparisonResults", default: nil)
    static let enableOCRComparison = Key<Bool>("enableOCRComparison", default: false)
    static let enableAutoOCRComparison = Key<Bool>("enableAutoOCRComparison", default: false)

    // Screen recording
    static let screenRecordingPermissionAsked = Key<Bool>("screenRecordingPermissionAsked", default: false)
    
    // Feature Disable (unified system for Sidekick)
    static let featureDisableRules = Key<[FeatureDisableRule]>("featureDisableRules", default: [])
    static let ignoredFeatureDisableRules = Key<[IgnoredFeatureDisableRule]>("ignoredFeatureDisableRules", default: [])
    static let sidekickDisabledInPrivateBrowser = Key<Bool>("sidekickDisabledInPrivateBrowser", default: true)
    static let capsLockModifierShortcuts = Key<[String]>("capsLockModifierShortcuts", default: [])
    
    // Debug overlays
    static let showVisualDiffDebugOverlay = Key<Bool>("showVisualDiffDebugOverlay", default: false)

    // Timed Check Dates
    static let lastCheckedValidRemoteTokens = Key<Date?>("lastCheckedValidRemoteTokens", default: nil)
    
    // Localization
    static let translationBuildLanguageCode = Key<String?>("translationBuildLanguageCode", default: nil)
    static let translationSourceLanguageCode = Key<String?>("translationSourceLanguageCode", default: nil)
    
    static let enableSidebar = Key<Bool>("enableSidebar", default: true)
}

extension NSRect: Defaults.Serializable {

}

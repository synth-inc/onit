//
//  Defaults.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import CoreGraphics
import Defaults
import Foundation

extension Defaults.Keys {
    static let isPanelExpanded = Key<Bool>("isPanelExpanded", default: false)
    static let defaultPanelFrame = Key<NSRect>(
        "defaultPanelFrame", default: NSRect(x: 0, y: 0, width: 400, height: 600))

    // Remote model tokens
    static let openAIToken = Key<String?>("openAIToken", default: nil)
    static let anthropicToken = Key<String?>("anthropicToken", default: nil)
    static let xAIToken = Key<String?>("xAIToken", default: nil)
    static let googleAIToken = Key<String?>("googleAIToken", default: nil)
    static let deepSeekToken = Key<String?>("deepSeekToken", default: nil)

    // Remote model validation
    static let isOpenAITokenValidated = Key<Bool>("openAITokenValidated", default: false)
    static let isAnthropicTokenValidated = Key<Bool>("anthropicTokenValidated", default: false)
    static let isXAITokenValidated = Key<Bool>("xAITokenValidated", default: false)
    static let isGoogleAITokenValidated = Key<Bool>("googleAITokenValidated", default: false)
    static let isDeepSeekTokenValidated = Key<Bool>("deepSeekTokenValidated", default: false)

    // Remote model usage
    static let useOpenAI = Key<Bool>("useOpenAI", default: false)
    static let useAnthropic = Key<Bool>("useAnthropic", default: false)
    static let useXAI = Key<Bool>("useXAI", default: false)
    static let useGoogleAI = Key<Bool>("useGoogleAI", default: false)
    static let useDeepSeek = Key<Bool>("useDeepSeek", default: false)
    static let useLocal = Key<Bool>("useLocalModel", default: false)
    
    static let streamResponse = Key<StreamResponseConfig>("streamResponse", default: StreamResponseConfig.default)

    // Dialogs closed
    static let closedRemote = Key<Bool>("closedRemote", default: false)
    static let closedLocal = Key<Bool>("closedLocal", default: false)
    static let closedOpenAI = Key<Bool>("closedOpenAI", default: false)
    static let closedAnthropic = Key<Bool>("closedAnthropic", default: false)
    static let closedXAI = Key<Bool>("closedXAI", default: false)
    static let closedGoogleAI = Key<Bool>("closedGoogleAI", default: false)
    static let closedDeepSeek = Key<Bool>("closedDeepSeek", default: false)
    static let closedNewRemoteData = Key<Data>("closedNewRemoteData", default: Data())
    static let closedDeprecatedRemoteData = Key<Data>("closedDeprecatedRemoteData", default: Data())
    static let closedAutoContextDialog = Key<Bool>("closedAutoContext", default: false)

    static let seenLocal = Key<Bool>("seenLocal", default: false)

    static let remoteModel = Key<AIModel?>("remoteModel", default: nil)
    static let localModel = Key<String?>("localModel", default: nil)
    static let mode = Key<InferenceMode>("mode", default: .remote)
    static let availableLocalModels = Key<[String]>("availableLocalModels", default: [])
    static let availableRemoteModels = Key<[AIModel]>("availableRemoteModels", default: [])
    static let availableCustomProviders = Key<[CustomProvider]>(
        "availableCustomProvider", default: [])

    // Stores unique model identifiers in the format "provider-id" or "customProviderName-id" for custom providers
    static let visibleModelIds = Key<Set<String>>("visibleModelIds", default: Set([]))
    static let hasPerformedModelIdMigration = Key<Bool>(
        "hasPerformedModelIdMigration", default: false)

    static let localEndpointURL = Key<URL>(
        "localEndpointURL", default: URL(string: "http://localhost:11434")!)

    // Feature flags
    static let accessibilityEnabled = Key<Bool?>("accessibilityEnabled", default: nil)
    static let accessibilityInputEnabled = Key<Bool?>("accessibilityInputEnabled", default: nil)
    static let accessibilityAutoContextEnabled = Key<Bool?>(
        "accessibilityAutoContextEnabled", default: nil)
    static let highlightHintMode = Key<HighlightHintMode?>("highlightHintMode", default: nil)

    // Window state
    static let panelWidth = Key<Double?>("panelWidth", default: nil)
    static let panelPosition = Key<PanelPosition>("panelPosition", default: .topRight)

    // General settings
    static let launchOnStartupRequested = Key<Bool>("launchOnStartupRequested", default: false)
    static let fontSize = Key<Double>("fontSize", default: 14.0)
    static let lineHeight = Key<Double>("lineHeight", default: 1.5)

    // Local model advanced options
    static let localKeepAlive = Key<String?>("localKeepAlive", default: nil)
    static let localNumCtx = Key<Int?>("localNumCtx", default: nil)
    static let localTemperature = Key<Double?>("localTemperature", default: nil)
    static let localTopP = Key<Double?>("localTopP", default: nil)
    static let localTopK = Key<Int?>("localTopK", default: nil)
    static let localRequestTimeout = Key<TimeInterval?>("localRequestTimeout", default: 60.0)
}

extension NSRect: Defaults.Serializable {

}

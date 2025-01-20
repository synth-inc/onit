//
//  Model.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import SageKit
import SwiftData
import Sparkle
import Combine
import AppKit

@MainActor @Observable class OnitModel: NSObject {
    var container: ModelContainer
    
    var tooltipWindow: NSWindow?
    var tooltip: Tooltip?
    var tooltipTask: Task<Void, Never>?
    var tooltipWidth: CGFloat = 0
    var tooltipHeight: CGFloat = 0
    var showTooltip = false
    var isTooltipActive = false
    var showHistory: Bool = false
    var incognitoMode: Bool = false
    var showMenuBarExtra: Bool = false
    var inputExpanded = true
    var panel: CustomPanel? = nil

    var currentChat: Chat?
    var currentPrompts: [Prompt]?

    // User inputs that have not yet been submitted
    var pendingInstruction = "" {
        didSet { pendingInstruction.save("pendingInstruction") }
    }
    var pendingContextList : [Context] = [] {
        didSet { pendingContextList.save("pendingContext") }
    }
    var pendingInput: Input? =  nil {
        didSet { pendingInput.save("pendingInput") }
    }
        
    var imageUploads: [URL: UploadProgress] = [:]
    var uploadTasks: [URL: Task<URL?, Never>] = [:]
    var textFocusTrigger = false
    var isOpeningSettings = false
    var historyIndex = -1

    var headerHeight: CGFloat = 0
    var inputHeight: CGFloat = 0
    var contentHeight: CGFloat = 0
    var setUpHeight: CGFloat = 0

    var showDebugWindow = false
    var debugPanel: CustomPanel? = nil
    var debugText: String?

    var modelSelectionWindowController: ModelSelectionWindowController?

    var trusted: Bool = true
    @ObservationIgnored var trustedTimer: AnyCancellable?

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil
    var generatingPrompt: Prompt?
    var generatingPromptPriorState: GenerationState?

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var _tokenValidation = TokenValidationState()
    
    @MainActor
    func fetchLocalModels() async {
        do {
            preferences.availableLocalModels = try await FetchingClient().getLocalModels()

            // Handle local model selection
            if preferences.availableLocalModels.isEmpty {
                preferences.localModel = nil
            } else if preferences.localModel == nil {
                preferences.localModel = preferences.availableLocalModels[0]
            } else if !preferences.availableLocalModels.contains(preferences.localModel!) {
                preferences.localModel = preferences.availableLocalModels[0]
            }
        } catch {
            print("Error fetching local models:", error)
            preferences.availableLocalModels = []
            preferences.localModel = nil
        }
    }

    init(container: ModelContainer) {
        self.pendingInput = Input?.load()
        self.pendingInstruction = String.load("instructions") ?? ""
        self.container = container
        super.init()
        self.preferences = Preferences.shared
        startTrustedTimer()
        Task {
            await fetchLocalModels()
        }
    }
    
    func updatePreferences(_ update: (inout Preferences) -> Void) {
        update(&preferences)
        Preferences.save(preferences)
    }
}

extension String {
    static let selectedModel = "SelectedModel"
}

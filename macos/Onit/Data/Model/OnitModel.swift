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
    var settingsTab: SettingsTab = .models
    var historyIndex = -1

    var headerHeight: CGFloat = 0
    var inputHeight: CGFloat = 0
    var contentHeight: CGFloat = 0
    var setUpHeight: CGFloat = 0
    var resizing = false

    var showDebugWindow = false
    var debugPanel: CustomPanel? = nil
    var debugText: String?

    var modelSelectionWindowController: ModelSelectionWindowController?

    var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notDetermined

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil
    var generatingPrompt: Prompt?
    var generatingPromptPriorState: GenerationState?

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var _tokenValidation = TokenValidationState()
    
    var remoteFetchFailed: Bool = false
    var localFetchFailed: Bool = false
    
    @MainActor
    func fetchLocalModels() async {
        do {
            let models = try await FetchingClient().getLocalModels()

            // Handle local model selection
            updatePreferences { prefs in
                preferences.availableLocalModels = models

                if preferences.availableLocalModels.isEmpty {
                    prefs.localModel = nil
                
                } else if preferences.localModel == nil || !preferences.availableLocalModels.contains(preferences.localModel!) {
                    prefs.localModel = preferences.availableLocalModels[0]
                }
                if listedModels.isEmpty {
                    prefs.mode = .local
                }
                localFetchFailed = false
            }
            
            // If relevant shrink the dialog box to account for the removed SetupDialog.
            shrinkContent()
        } catch {
            print("Error fetching local models:", error)
            updatePreferences { prefs in
                localFetchFailed = true
                prefs.availableLocalModels = []
                prefs.localModel = nil
            }
        }
    }
    
    @MainActor
    func fetchRemoteModels() async {
        do {
            // if
            var models = try await AIModel.fetchModels()
            
            // This means we've never successfully fetched before
            if preferences.availableRemoteModels.isEmpty {
                updatePreferences { prefs in
                    prefs.initializeVisibleModelIds(from: models)
                    prefs.availableRemoteModels = models
                    if !listedModels.isEmpty {
                        prefs.remoteModel = listedModels.first
                    }

                    // If relevant shrink the dialog box to account for the removed SetupDialog.
                    shrinkContent()
                }
            } else {
                updatePreferences { prefs in
                    // Update the availableRemoteModels with the newly fetched models
                    let newModelIds = Set(models.map { $0.id })
                    let existingModelIds = Set(prefs.availableRemoteModels.map { $0.id })
                    
                    let newModels = models.filter { !existingModelIds.contains($0.id) }
                    var deprecatedModels = prefs.availableRemoteModels.filter { !newModelIds.contains($0.id) }
                    for index in models.indices where newModels.contains(models[index]) {
                        models[index].isNew = true
                    }
                    
                    for index in deprecatedModels.indices {
                        deprecatedModels[index].isDeprecated = true
                    }

                    // We only save deprecated models if the user has them visibile. Otherwise, quietly remove them from the list. 
                    let visibleModelIds = Set(prefs.visibleModelIds)
                    let visibleDeprecatedModels = deprecatedModels.filter { visibleModelIds.contains($0.id) }
                    
                    remoteFetchFailed = false
                    prefs.availableRemoteModels = models + visibleDeprecatedModels
                    prefs.initializeVisibleModelIds(from: (models + visibleDeprecatedModels))

                    
                    if !listedModels.isEmpty && (preferences.remoteModel == nil || !preferences.availableRemoteModels.contains(preferences.remoteModel!)) {
                        prefs.remoteModel = preferences.availableRemoteModels[0]
                    }

                    // If relevant shrink the dialog box to account for the removed SetupDialog.
                    shrinkContent()
                }
            }

            
        } catch {
            print("Error fetching local models:", error)
            remoteFetchFailed = true
        }
    }

    init(container: ModelContainer) {
        // TODO: KNA - Checks this
        // self.pendingInput = Input?.load()
        // self.pendingInstruction = String.load("instructions") ?? ""
        self.container = container
        super.init()
        self.preferences = Preferences.shared
        Task {
            await fetchLocalModels()
            await fetchRemoteModels()
            
            // This handles an edge case where Ollama is running but there is no internet connection
            // We put the user in localmode so they can use the product.
            // We don't do the opposite, becuase we don't want to put the product in remote mode without them knowing.
            if !preferences.availableLocalModels.isEmpty && preferences.availableRemoteModels.isEmpty {
                preferences.mode = .local
            }
        }
    }
    
    func updatePreferences(_ update: (inout Preferences) -> Void) {
        update(&preferences)
        Preferences.save(preferences)
    }
    
    func setSettingsTab(tab: SettingsTab) {
        settingsTab = tab
    }
}

extension String {
    static let selectedModel = "SelectedModel"
}

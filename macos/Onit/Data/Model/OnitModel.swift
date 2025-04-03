//
//  Model.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import AppKit
import Combine
import Defaults
import Sparkle
import SwiftData
import SwiftUI

@MainActor @Observable class OnitModel: NSObject {
    var container: ModelContainer
    var remoteModels: RemoteModelsState

    var tooltipWindow: NSWindow?
    var tooltip: Tooltip?
    var tooltipTask: Task<Void, Never>?
    var tooltipWidth: CGFloat = 0
    var tooltipHeight: CGFloat = 0
    var showTooltip = false
    var isTooltipActive = false
    var showHistory: Bool = false
    var showMenuBarExtra: Bool = false
    weak var panel: CustomPanel? = nil {
        didSet {
            isPanelOpened.send(panel != nil)
        }
    }
    var isPanelOpened = PassthroughSubject<Bool, Never>()
    var isPanelMiniaturized = PassthroughSubject<Bool, Never>()

    var currentChat: Chat?
    var currentPrompts: [Prompt]?
    
    var deleteChatFailed: Bool = false

    // User inputs that have not yet been submitted
    var pendingInstruction = "" {
        didSet {
            pendingInstructionSubject.send(pendingInstruction)
        }
    }
    var pendingInstructionSubject = CurrentValueSubject<String, Never>("")
    var pendingInstructionCursorPosition: Int = 0
    
    var pendingContextList: [Context] = [] {
        didSet {
            pendingContextListSubject.send(pendingContextList)
        }
    }
    var pendingContextListSubject = CurrentValueSubject<[Context], Never>([])
    
    var pendingInput: Input? = nil {
        didSet {
            pendingInputSubject.send(pendingInput)
        }
    }
    var pendingInputSubject = CurrentValueSubject<Input?, Never>(nil)

    var imageUploads: [URL: UploadProgress] = [:]
    var uploadTasks: [URL: Task<URL?, Never>] = [:]
    var textFocusTrigger = false
    var settingsTab: SettingsTab = .models
    var historyIndex = -1

    var headerHeight: CGFloat = 0
    var inputHeight: CGFloat = 0
    var contentHeight: CGFloat = 0
    var setUpHeight: CGFloat = 0
    var systemPromptHeight: CGFloat = 0
    var resizing = false

    var showDebugWindow = false
    var debugPanel: CustomPanel? = nil
    var debugText: String?

    var contextWindowControllers: [Context: ContextWindowController] = [:]

    var showFileImporter = false

    var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notDetermined

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil
    var generatingPrompt: Prompt?
    var generatingPromptPriorState: GenerationState?

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var streamingClient = StreamingClient()
    var _tokenValidation = TokenValidationState()

    var remoteFetchFailed: Bool = false
    var localFetchFailed: Bool = false

    var streamedResponse: String = ""
    
    var promptSuggestionService: SystemPromptSuggestionService?
    
    // Web search state
    var webSearchError: Error? = nil
    var isSearchingWeb: [PersistentIdentifier: Bool] = [:]
    
    typealias WebsiteUrlScrapeTask = Task<Void, Never>
    var websiteUrlsScrapeQueue: [String: WebsiteUrlScrapeTask] = [:]

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
            if remoteModels.listedModels.isEmpty {
                Defaults[.mode] = .local
            }
            localFetchFailed = false

            // Reset the closedNoLocalModels flag when local models are successfully fetched.
            Defaults[.closedNoLocalModels] = false

            // If relevant shrink the dialog box to account for the removed SetupDialog.
            shrinkContent()
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
                if !remoteModels.listedModels.isEmpty {
                    Defaults[.remoteModel] = remoteModels.listedModels.first
                }
                // If relevant shrink the dialog box to account for the removed SetupDialog.
                shrinkContent()
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

                if !remoteModels.listedModels.isEmpty
                    && (Defaults[.remoteModel] == nil
                        || !Defaults[.availableRemoteModels].contains(Defaults[.remoteModel]!))
                {
                    Defaults[.remoteModel] = Defaults[.availableRemoteModels].first
                }

                // If relevant shrink the dialog box to account for the removed SetupDialog.
                shrinkContent()
            }

        } catch {
            print("Error fetching local models:", error)
            remoteFetchFailed = true
        }
    }

    init(container: ModelContainer, remoteModels: RemoteModelsState) {
        // TODO: KNA - Checks this
        // self.pendingInput = Input?.load()
        // self.pendingInstruction = String.load("instructions") ?? ""
        self.container = container
        self.remoteModels = remoteModels
        super.init()

        Task {
            await fetchLocalModels()
            await fetchRemoteModels()

            // This handles an edge case where Ollama is running but there is no internet connection
            // We put the user in localmode so they can use the product.
            // We don't do the opposite, becuase we don't want to put the product in remote mode without them knowing.
            if !Defaults[.availableLocalModels].isEmpty && Defaults[.availableRemoteModels].isEmpty
            {
                Defaults[.mode] = .local
            }
        }

        self.promptSuggestionService = SystemPromptSuggestionService(model: self)
    }

    func setSettingsTab(tab: SettingsTab) {
        settingsTab = tab
    }
}

extension String {
    static let selectedModel = "SelectedModel"
}

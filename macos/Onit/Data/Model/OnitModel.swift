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
    var generationState: GenerationState = .idle
    var inputExpanded = true
    var panel: CustomPanel? = nil
    var input: Input? = nil {
        didSet { input.save() }
    }
    var availableLocalModels: [String] = []
    var youSaid: String?
    var prompt: Prompt?
    var context: [Context] = []
    var sourceText: String?
    var selectedText: String?
    var imageUploads: [URL: UploadProgress] = [:]
    var uploadTasks: [URL: Task<URL?, Never>] = [:]
    var textFocusTrigger = false
    var isOpeningSettings = false
    var historyIndex = -1
    var generationIndex = 0
    var instructions = "" {
        didSet { instructions.save("instructions") }
    }
    
    var showDebugWindow = false
    var debugPanel: CustomPanel? = nil
    var debugText: String?

    var trusted: Bool = true
    @ObservationIgnored var trustedTimer: AnyCancellable?

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    var _tokenValidation = TokenValidationState()
    
    @MainActor
    func fetchLocalModels() async {
        do {
            availableLocalModels = try await FetchingClient().getLocalModels()
            
            // Handle local model selection
            if availableLocalModels.isEmpty {
                preferences.localModel = nil
            } else if preferences.localModel == nil {
                preferences.localModel = availableLocalModels[0]
            } else if !availableLocalModels.contains(preferences.localModel!) {
                preferences.localModel = availableLocalModels[0]
            }
        } catch {
            print("Error fetching local models:", error)
            availableLocalModels = []
            preferences.localModel = nil
        }
    }

    init(container: ModelContainer) {
        self.input = Input?.load()
        self.instructions = String.load("instructions") ?? ""
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

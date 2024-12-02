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
    
    var showMenuBarExtra: Bool = false
    var generationState: GenerationState = .idle
    var inputExpanded = true
    var panel: CustomPanel? = nil
    var input: Input? = nil {
        didSet { input.save() }
    }
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

    init(container: ModelContainer) {
        self.input = Input?.load()
        self.instructions = String.load("instructions") ?? ""
        self.container = container
        super.init()
        startTrustedTimer()
    }

}

extension String {
    static let selectedModel = "SelectedModel"
}

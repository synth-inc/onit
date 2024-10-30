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
        didSet {
            input.save()
        }
    }
    var tooltipFrame: CGRect?
    var context: [Context] = []
    var imageUploads: [URL: UploadProgress] = [:]
    var uploadTasks: [URL: Task<URL?, Never>] = [:]
    var textFocusTrigger = false
    var isOpeningSettings = false

    var trusted: Bool = true
    private var trustedTimer: AnyCancellable?

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    init(container: ModelContainer) {
        self.input = Input?.load()
        self.container = container
        super.init()
        startTrustedTimer()
    }

    func startTrustedTimer() {
        trustedTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let currentStatus = Accessibility.trusted
                if self?.trusted != currentStatus {
                    self?.trusted = currentStatus
                }
            }
    }
}

extension String {
    static let selectedModel = "SelectedModel"
}

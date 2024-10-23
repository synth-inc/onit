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

@MainActor
@Observable
class OnitModel: NSObject {
    var showMenuBarExtra: Bool = false
    var generationState: GenerationState = .idle
    var panel: CustomPanel? = nil
    var input: Input? = nil
    var context: [URL] = []
    var textFocusTrigger = false
    var isOpeningSettings = false

    var trusted: Bool = true
    private var trustedTimer: AnyCancellable?

    var droppedItems = [(image: NSImage, filename: String)]()

    var generateTask: Task<Void, Never>? = nil

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    override init() {
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

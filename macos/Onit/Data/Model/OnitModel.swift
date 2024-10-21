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

@Observable class OnitModel: NSObject {
    var showMenuBarExtra: Bool = false
    var generationState: GenerationState = .idle
    var panel: CustomPanel? = nil
    var input: Input? = nil
    var textFocusTrigger = false

    var generateTask: Task<Void, Never>? = nil

    var client = FetchingClient()
    var updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    override init() {
        super.init()
    }
}

extension String {
    static let selectedModel = "SelectedModel"
}

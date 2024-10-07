//
//  Model.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import SageKit

@MainActor @Observable class Model: NSObject {
    var showMenuBarExtra = false
    var generationState: GenerationState = .idle
    var panel: CustomPanel?
    var input: Input?
    var textFocusTrigger = false

    var generateTask: Task<Void, Never>? = nil

    let client = FetchingClient()
}

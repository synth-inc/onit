//
//  SystemPromptState.swift
//  Onit
//
//  Created by Kévin Naudin on 02/02/2025.
//

import SwiftUI

@Observable
class SystemPromptState {
    var activeApplication: String?
    var shouldShowSystemPrompt: Bool = false
    var shouldShowSelection: Bool = false
    var userSelectedPrompt: Bool = false
}

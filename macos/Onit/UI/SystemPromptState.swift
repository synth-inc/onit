//
//  SystemPromptState.swift
//  Onit
//
//  Created by Kévin Naudin on 02/02/2025.
//

import SwiftUI

@Observable
final class SystemPromptState {
    
    @MainActor static let shared = SystemPromptState()
    
    var activeApplication: String?
    var shouldShowSystemPrompt: Bool = false
    var shouldShowSelection: Bool = false
}

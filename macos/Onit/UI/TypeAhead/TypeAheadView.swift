//
//  TypeAheadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import SwiftUI

struct TypeAheadView: View {
    @ObservedObject var accessibilityManager = AccessibilityNotificationsManager.shared
    @Default(.typeAheadConfig) var typeAheadConfig
    
    private let moreSuggestionsState = TypeAheadMoreSuggestionsState.shared
    
    private var isPaused: Bool {
        guard let resumeAt = typeAheadConfig.resumeAt,
              resumeAt > .now else {
            return false
        }
        
        return true
    }
    
    private var isAppExcluded: Bool {
        guard let appName = accessibilityManager.screenResult.applicationName else { return false }
        
        return typeAheadConfig.excludedApps.contains(where: appName.contains)
    }
    
    var body: some View {
        Group {
            if isPaused {
                TypeAheadDisabledView(reason: "Auto-complete paused")
            } else if isAppExcluded {
                let appName = accessibilityManager.screenResult.applicationName ?? ""
                
                TypeAheadDisabledView(reason: "Auto-complete disabled for \"\(appName)\"")
            } else {
                if !moreSuggestionsState.isLoading && moreSuggestionsState.moreSuggestions.isEmpty {
                    TypeAheadCompletionView()
                } else {
                    TypeAheadMoreSuggestionsView()
                }
            }
        }
    }
}

#Preview {
    TypeAheadView()
}

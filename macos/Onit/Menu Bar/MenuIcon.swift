//
//  MenuIcon.swift
//  Onit
//
//  Created by Benjamin Sage on 10/22/24.
//

import Combine
import SwiftUI
import Defaults

struct MenuIcon: View {
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @Default(.tetheredButtonHideAllApps) var tetheredButtonHideAllApps
    @Default(.tetheredButtonHideAllAppsTimerDate) var tetheredButtonHideAllAppsTimerDate
    @Default(.collectTypeaheadTestCases) var collectTypeaheadTestCases
    
    @State private var currentTime: Date = Date()
    @State private var timerUpdateTask: Task<Void, Never>? = nil
    
    private var isHideAllAppsTimerActive: Bool {
        guard let timerDate = tetheredButtonHideAllAppsTimerDate else { return false }
        return timerDate > currentTime
    }
    
    private var isOnitDisabled: Bool {
        tetheredButtonHideAllApps || isHideAllAppsTimerActive
    }

    private var iconImage: ImageResource {

        // Typeahead recording state for normal operation
        if collectTypeaheadTestCases {
            // Recording active - use active state
#if BETA
            return .noodleActiveBeta // Use beta version when recording in beta
#else
            return .noodleActive // Use regular active icon when recording
#endif
        } else {
            // Not recording - use warning state to indicate inactive recording
#if BETA
            return .noodleWarningBeta
#else
            return .noodleWarning
#endif
        }

//         let statusGranted = accessibilityPermissionManager.accessibilityPermissionStatus == .granted
        
//         // Accessibility permission takes highest priority
//         if !statusGranted {
// #if BETA
//             return .noodleErrorBeta
// #else
//             return .noodleError
// #endif
//         }
        
//         // App disabled state takes second priority
//         if isOnitDisabled {
// #if BETA
//             return .noodleWarningBeta
// #else
//             return .noodleWarning
// #endif
//         }
        

    }
    
    var body: some View {
        Image(iconImage)
            .renderingMode(.original)
//            .animation(.default, value: isOnitDisabled)
            .onAppear {
                startTimerUpdateTaskIfNeeded()
            }
            .onDisappear {
                stopTimerUpdateTask()
            }
            .onChange(of: tetheredButtonHideAllAppsTimerDate) { _, newValue in
                if newValue != nil {
                    startTimerUpdateTaskIfNeeded()
                } else {
                    stopTimerUpdateTask()
                }
            }
    }
    
    private func startTimerUpdateTaskIfNeeded() {
        guard tetheredButtonHideAllAppsTimerDate != nil else { return }
        
        timerUpdateTask?.cancel()
        timerUpdateTask = Task {
            while !Task.isCancelled {
                currentTime = Date()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func stopTimerUpdateTask() {
        timerUpdateTask?.cancel()
        timerUpdateTask = nil
    }
}

#if DEBUG
    #Preview {
        MenuIcon()
    }
#endif

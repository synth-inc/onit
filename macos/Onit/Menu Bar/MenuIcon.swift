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
        let statusGranted = accessibilityPermissionManager.accessibilityPermissionStatus == .granted
        if !statusGranted {
#if BETA
            return .noodleErrorBeta
#else
            return .noodleError
#endif
        } else if isOnitDisabled {
#if BETA
            return .noodleWarningBeta
#else
            return .noodleWarning
#endif
        } else {
#if BETA
            return .noodleBeta
#else
            return .noodle
#endif
        }
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
        // Only start timer if there's a timer date set and no task is already running
        guard tetheredButtonHideAllAppsTimerDate != nil, timerUpdateTask == nil else { return }
        
        timerUpdateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    await MainActor.run {
                        currentTime = Date()
                        
                        // Clean up expired timer
                        if let timerDate = tetheredButtonHideAllAppsTimerDate,
                           timerDate <= currentTime {
                            tetheredButtonHideAllAppsTimerDate = nil
                            tetheredButtonHideAllApps = false
                        }
                    }
                }
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

//
//  MenuHideTimerStatus.swift
//  Onit
//
//  Created by Assistant on 02/04/2025.
//

import SwiftUI
import Defaults

struct MenuHideTimerStatus: View {
    @Default(.tetheredButtonHideAllApps) private var tetheredButtonHideAllApps
    @Default(.tetheredButtonHideAllAppsTimerDate) private var tetheredButtonHideAllAppsTimerDate
    
    @State private var currentTime: Date = Date()
    @State private var timerUpdateTask: Task<Void, Never>? = nil
    
    private var isHideAllAppsTimerActive: Bool {
        guard let timerDate = tetheredButtonHideAllAppsTimerDate else { return false }
        return timerDate > currentTime
    }
    
    private var shouldShowRow: Bool {
        isHideAllAppsTimerActive || tetheredButtonHideAllApps
    }
    
    private var remainingTimeString: String {
        guard let timerDate = tetheredButtonHideAllAppsTimerDate else { return "" }
        
        let timeInterval = timerDate.timeIntervalSince(currentTime)
        if timeInterval <= 0 { return "Expired" }
        
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private var statusText: String {
        if isHideAllAppsTimerActive {
            return "Hidden for \(remainingTimeString)"
        } else if tetheredButtonHideAllApps {
            return "Hidden everywhere"
        } else {
            return ""
        }
    }
    
    var body: some View {
        if shouldShowRow {
            hideTimerRow
        }
    }
    
    private var hideTimerRow: some View {
        MenuBarRow {
            cancelHideTimer()
        } leading: {
            HStack(spacing: 9) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
                Text(statusText)
            }
            .padding(.horizontal, 10)
        } trailing: {
            Text("Unhide")
                .foregroundStyle(.gray200)
                .font(.system(size: 13))
                .padding(.trailing, 10)
        }
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
    
    private func cancelHideTimer() {
        tetheredButtonHideAllAppsTimerDate = nil
        tetheredButtonHideAllApps = false
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

#Preview {
    MenuHideTimerStatus()
} 

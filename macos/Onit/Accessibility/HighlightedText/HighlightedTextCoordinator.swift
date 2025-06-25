//
//  HighlightedTextCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import Cocoa
import Defaults
import ApplicationServices

actor HighlightedTextCoordinator {
    static let appNames: [String] = [
        "Notes",
        "iTerm2"
    ]
    
    private var workerByPID: [pid_t: HighlightedTextWorker] = [:]

    func startPollingIfNeeded(
        pid: pid_t,
        interval: TimeInterval = 0.5,
        selectionChangedHandler: @escaping @Sendable (AXUIElement?, String?) -> Void
    ) {
        stopPolling(pid: pid)

        guard let appName = pid.appName, Self.appNames.contains(appName) else {
            return
        }
        
        let worker = HighlightedTextWorker(
            pid: pid,
            interval: interval,
            selectionChangedHandler: selectionChangedHandler
        )
        worker.start()
        
        workerByPID[pid] = worker
    }

    func stopPolling(pid: pid_t) {
        workerByPID[pid]?.stop()
        workerByPID[pid] = nil
    }
    
    func reset() {
        for (_, worker) in workerByPID {
            worker.stop()
        }
        
        workerByPID.removeAll()
    }
}

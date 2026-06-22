//
//  TimeProfiler.swift
//  Onit
//
//  Created by Kévin Naudin on 09/09/2025.
//

import Foundation

@MainActor
class TimeProfiler {
    
    // MARK: - Singleton instance
    
    static let shared = TimeProfiler()
    
    // MARK: - Properties
    
    private struct Session {
        var startTime: CFAbsoluteTime
        var steps: [(name: String, time: CFAbsoluteTime)] = []
    }
    
    private var sessions: [String: Session] = [:]
    private let defaultTask = "__default__"
    
    // MARK: - Public Functions
    
    func start(task name: String? = nil) {
        let key = name ?? defaultTask
        
        if sessions[key] == nil {
            sessions[key] = Session(startTime: CFAbsoluteTimeGetCurrent())
        }
    }
    
    func step(_ label: String, task name: String? = nil) {
        let key = name ?? defaultTask
        
        start(task: name)
        
        guard var session = sessions[key] else {
            return
        }
        
        let now = CFAbsoluteTimeGetCurrent()
        
        session.steps.append((label, now - session.startTime))
        sessions[key] = session
    }
    
    func end(task name: String? = nil) {
        let key = name ?? defaultTask
        let taskName = name ?? "default"
        
        guard let session = sessions[key] else {
            log.debug("⚠️ TimeProfiler: task '\(key)' not started.")
            return
        }
        
        let total = (CFAbsoluteTimeGetCurrent() - session.startTime) * 1000
        
        for i in 0..<session.steps.count {
            let step = session.steps[i]
            let previousTime = i == 0 ? 0 : session.steps[i-1].time
            let duration = (step.time - previousTime) * 1000
            
            print("⏳ \(taskName) - \(step.name): \(String(format: "%.2f", duration)) ms")
        }
        
        print("⏳ \(taskName) - Total: \(String(format: "%.2f", total)) ms\n")
        
        sessions.removeValue(forKey: key)
    }
    
    func endAll() {
        for key in sessions.keys {
            end(task: key == defaultTask ? nil : key)
        }
    }
}

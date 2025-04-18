//
//  GlobalDragManager.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

import AppKit
import Combine

@MainActor
class GlobalDragManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var isDragging = false
    
    private var globalMonitor: Any?
    
    // MARK: - Functions
    
    func startMonitoring() {
        stopMonitoring()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.handleMouseUp()
        }
    }
    
    func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
    
    func startDragging() {
        isDragging = true
    }
    
    // MARK: - Private functions
    
    private func handleMouseUp() {
        if isDragging {
            isDragging = false
        }
    }
} 

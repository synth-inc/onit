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
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            switch event.type {
            case .leftMouseDragged:
                self?.handleMouseDragged(event)
            case .leftMouseUp:
                self?.handleMouseUp()
            default:
                break
            }
        }
    }
    
    func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        isDragging = false
    }
    
    // MARK: - Private functions
    
    private func handleMouseDragged(_ event: NSEvent) {
        if !isDragging {
            isDragging = true
        }
    }
    
    private func handleMouseUp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isDragging = false
        }
    }
} 

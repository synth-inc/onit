//
//  MouseNotificationManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/25/25.
//

import Foundation
import AppKit

// MARK: - Mouse Notification Manager
@MainActor
final class MouseNotificationManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = MouseNotificationManager()

    // MARK: - Properties

    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    private var isMonitoring: Bool = false
    private var isDragging: Bool = false
    private var lastClickTime: TimeInterval = 0
    private var clickCount: Int = 0
    private var dragStartLocation: NSPoint = .zero

    // MARK: - Delegates

    private var delegates = NSHashTable<AnyObject>.weakObjects()

    func addDelegate(_ delegate: MouseNotificationDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: MouseNotificationDelegate) {
        delegates.remove(delegate)
    }

    private func notifyDelegates(_ notification: (MouseNotificationDelegate) -> Void) {
        for case let delegate as MouseNotificationDelegate in delegates.allObjects {
            notification(delegate)
        }
    }

    // MARK: - Private initializer

    private init() {
        startMonitoring()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard !isMonitoring else { return }

        // Monitor mouse events
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp, .rightMouseDragged]) { [weak self] event in
            self?.handleMouseEvent(event)
        }

        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else {
            return
        }

        if let localEventMonitor = localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }

        isMonitoring = false
    }

    // MARK: - Private Methods

    private func handleMouseEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .rightMouseDown:
            handleMouseDown(event: event)
        case .leftMouseUp, .rightMouseUp:
            handleMouseUp(event: event)
        case .leftMouseDragged, .rightMouseDragged:
            handleMouseDragged(event: event)
        default:
            break
        }
    }

    private func handleMouseDown(event: NSEvent) {
        // Start tracking potential drag
        isDragging = false
        dragStartLocation = event.locationInWindow
        
        // Handle click events based on click count
        switch event.clickCount {
        case 1:
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didReceiveSingleClick: event)
            }
        case 2:
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didReceiveDoubleClick: event)
            }
        case 3:
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didReceiveTripleClick: event)
            }
        default:
            // For clicks beyond triple, treat as single click
            break
        }
    }

    private func handleMouseUp(event: NSEvent) {
        if isDragging {
            // End drag operation
            isDragging = false
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didEndDrag: event)
            }
        }
    }

    private func handleMouseDragged(event: NSEvent) {
        let dragDistance = hypot(event.locationInWindow.x - dragStartLocation.x, 
                               event.locationInWindow.y - dragStartLocation.y)
        
        // Start drag if we've moved more than 3 points
        if !isDragging && dragDistance > 3.0 {
            isDragging = true
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didStartDrag: event)
            }
        }
        
        // Update drag if already dragging
        if isDragging {
            notifyDelegates { delegate in
                delegate.mouseNotificationManager(self, didUpdateDrag: event)
            }
        }
    }

    // MARK: - Utility Methods

    func getCurrentDragState() -> Bool {
        return isDragging
    }
    
    func getLastClickCount() -> Int {
        return clickCount
    }
deinit {
        stopMonitoring()
    }
}

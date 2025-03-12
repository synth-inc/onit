//
//  SplitViewManager.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

import AppKit
import Combine
import Defaults

@MainActor
class SplitViewManager: ObservableObject {
    static let shared = SplitViewManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() { }
    
    func startObserving() {
        stopObserving()

        AccessibilityNotificationsManager.shared.$windowBounds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bounds in
                guard Defaults[.splitViewModeEnabled],
                      let window = bounds.window,
                      let position = bounds.position,
                      let size = bounds.size else { return }
                
                self?.repositionWindow(window: window, position: position, size: size)
            }
            .store(in: &cancellables)
    }
    
    private func stopObserving() {
        cancellables.removeAll()
    }
    
    private func repositionWindow(window: AXUIElement, position: CGPoint, size: CGSize) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let minOnitWidth: CGFloat = ContentView.minWidth
        let activeAppWidth = min(size.width, screenFrame.width - minOnitWidth)
        let onitWidth = max(minOnitWidth, screenFrame.width - activeAppWidth)
        
        if window.setFrame(CGRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: activeAppWidth,
            height: screenFrame.height
        )) {
            if let onitWindow = NSApp.windows.first {
                onitWindow.deminiaturize(nil)
                onitWindow.setFrame(NSRect(
                    x: screenFrame.minX + activeAppWidth,
                    y: screenFrame.minY,
                    width: onitWidth,
                    height: screenFrame.height
                ), display: true, animate: true)
            }
        }
    }
}

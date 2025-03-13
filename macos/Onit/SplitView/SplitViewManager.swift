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
    
    private var model: OnitModel?
    private var cancellables = Set<AnyCancellable>()
    
    private let minOnitWidth: CGFloat = ContentView.idealWidth
    private let spaceBetweenWindows: CGFloat = 0
    
    private init() { }
    
    func configure(model: OnitModel) {
        self.model = model
    }
    
    func startObserving() {
        stopObserving()

        guard let model = model else { return }
        
        let activeWindowElement = AccessibilityNotificationsManager.shared.$activeWindowElement
        let isPanelOpened = model.isPanelOpened
            .prepend(model.panel != nil)
        let isPanelMiniaturized = model.isPanelMiniaturized
            .prepend(model.panel?.isMiniaturized ?? false)
        let isPanelOpenedAndNotMinimized = Publishers.CombineLatest(isPanelOpened, isPanelMiniaturized)
            .map { $0 && !$1 }
        
        Publishers.CombineLatest(activeWindowElement, isPanelOpenedAndNotMinimized)
            .debounce(for: 0.05, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (window, isPanelOpened) in
                guard Defaults[.isRegularApp],
                      let window = window,
                      isPanelOpened else { return }
                
                self?.repositionWindow(window: window)
            }
            .store(in: &cancellables)
    }
    
    private func stopObserving() {
        cancellables.removeAll()
    }
    
    private func repositionWindow(window: AXUIElement) {
        guard let screen = NSScreen.main,
              let panel = model?.panel,
              let position = window.position(),
              let size = window.size() else { return }
        
        let screenFrame = screen.visibleFrame
        let maxActiveAppWidth = screenFrame.width - minOnitWidth - spaceBetweenWindows
        let activeAppWidth = min(size.width, maxActiveAppWidth)
        let onitX = position.x + activeAppWidth + spaceBetweenWindows
        let onitWidth = max(minOnitWidth, screenFrame.maxX - onitX)
        
        if window.setFrame(CGRect(
            x: position.x,
            y: position.y,
            width: activeAppWidth,
            height: size.height
        )) {
            panel.setFrame(NSRect(
                x: onitX,
                y: screenFrame.minY,
                width: onitWidth,
                height: screenFrame.height
            ), display: true, animate: true)
        }
    }
}

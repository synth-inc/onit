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
    
    // MARK: - Singleton instance
    static let shared = SplitViewManager()
    
    // MARK: - Properties
    private var model: OnitModel?
    private var cancellables = Set<AnyCancellable>()
    
    private let minOnitWidth: CGFloat = ContentView.idealWidth
    private let spaceBetweenWindows: CGFloat = -(ContentView.fitActiveWindowWidth / 2)
    
    private var targetApplicationPID: pid_t?
    private var targetInitialFrame: CGRect?
    
    // MARK: - Private initializer
    private init() { }
    
    // MARK: - Functions
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
        let fitActiveWindowPublisher = Defaults.publisher(.fitActiveWindow)
            .map(\.newValue)
        
        Publishers.CombineLatest(fitActiveWindowPublisher, isPanelOpenedAndNotMinimized)
            .sink { [weak self] isEnabled, isOpened in
                if isEnabled && isOpened {
                    if let window = AccessibilityNotificationsManager.shared.activeWindowElement {
                        self?.targetInitialFrame = window.frame()
                        
                        if let pid = window.pid() {
                            self?.targetApplicationPID = pid
                            self?.model?.panel?.level = .floating
                        }
                    }
                } else {
                    if let pid = self?.targetApplicationPID,
                       let initialFrame = self?.targetInitialFrame,
                       let window = pid.getAXUIElement().children()?.first {
                        
                        _ = window.setFrame(initialFrame)
                    }
                    
                    self?.targetApplicationPID = nil
                    self?.targetInitialFrame = nil
                    self?.model?.panel?.level = .floating
                }
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(activeWindowElement, isPanelOpenedAndNotMinimized, fitActiveWindowPublisher)
            .debounce(for: 0.05, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (window, isPanelOpened, fitActiveWindow) in
                guard Defaults[.isRegularApp],
                      fitActiveWindow,
                      isPanelOpened,
                      let window = window,
                      let currentPID = window.pid() else { return }
                
                if currentPID == self?.targetApplicationPID {
                    self?.model?.panel?.level = .floating
                } else {
                    self?.model?.panel?.level = .normal
                }
                
                guard currentPID == self?.targetApplicationPID else { return }
                
                self?.repositionWindow(window: window)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private functions
    private func stopObserving() {
        cancellables.removeAll()
    }
    
    private func repositionWindow(window: AXUIElement) {
        guard let panel = model?.panel,
              let position = window.position(),
              let size = window.size() else { return }
        
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.visibleFrame
        let maxActiveAppWidth = screenFrame.width - minOnitWidth - spaceBetweenWindows
        let activeAppWidth = min(size.width, maxActiveAppWidth)
        
        let relativeX = max(position.x - screenFrame.minX, 0)
        let relativeOnitX = relativeX + activeAppWidth + spaceBetweenWindows
        let onitX = screenFrame.minX + min(relativeOnitX, screenFrame.width - minOnitWidth)
        let onitWidth = max(minOnitWidth, screenFrame.maxX - onitX)
        let onitHeight = screenFrame.height - ContentView.bottomPadding
        let onitY = screenFrame.minY + (screenFrame.height - onitHeight)
        
        if window.setFrame(CGRect(
            x: position.x,
            y: position.y,
            width: activeAppWidth,
            height: size.height
        )) {
            panel.setFrame(NSRect(
                x: onitX,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            ), display: true, animate: true)
        }
    }
}

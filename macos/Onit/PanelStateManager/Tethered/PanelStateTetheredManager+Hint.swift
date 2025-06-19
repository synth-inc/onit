//
//  PanelStateTetheredManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

@preconcurrency import ApplicationServices
import SwiftUI

extension PanelStateTetheredManager {
    
    func debouncedShowTetherWindow(
        state: OnitPanelState,
        activeWindow: AXUIElement,
        action: TrackedWindowAction
    ) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeWindow)

        tetherHintDetails.showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: tetherHintDetails.showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showTetherWindow(state: pendingTetherWindow.0, activeWindow: pendingTetherWindow.1, action: action)
            }
        }
    }
    
    // MARK: - Private functions
    
    private func showTetherWindow(state: OnitPanelState, activeWindow: AXUIElement?, action: TrackedWindowAction) {
        let tetherView = ExternalTetheredButton(
            onClick: {
                PanelStateCoordinator.shared.launchPanel(for: state)
            },
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ).environment(\.windowState, state)
        
        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherHintDetails.lastYComputed = nil
        tetherButtonPanelState = state

        updateTetherWindowPosition(for: activeWindow, action: action, lastYComputed: tetherHintDetails.lastYComputed)
        
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func updateTetherWindowPosition(for window: AXUIElement?, action: TrackedWindowAction, lastYComputed: CGFloat? = nil) {
        guard let activeWindow = window,
              let activeWindowFrame = activeWindow.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }
        var positionX = activeWindowFrame.origin.x + activeWindowFrame.width - ExternalTetheredButton.containerWidth
        var optionalWindowFrame: CGRect?
        
        if activeWindow.isFinder {
            if activeWindow.isDesktopFinder {
                if let mouseScreen = NSScreen.mouse {
                    let screenFrame = mouseScreen.visibleFrame
               
                    optionalWindowFrame = screenFrame
                    positionX = screenFrame.maxX - ExternalTetheredButton.containerWidth
                }
            } else {
                // These are clicks on the desktop. The appActivation logic gives us the most recent
                // Finder window, but it could be behind other windows or minimized, so we don't want
                // to move the hint to it.
                if let isMain = activeWindow.isMain(), let isMinimized = activeWindow.isMinimized() {
                    if !isMain || isMinimized {
                        print("This is a click on the desktop, remove tether window")
                        hideTetherWindow()
                        return
                    }
                }
            }
        }
        let windowFrame = optionalWindowFrame ?? activeWindowFrame
        
        var positionY: CGFloat
        if lastYComputed == nil {
            positionY = windowFrame.minY + (windowFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        } else {
            positionY = computeTetheredWindowY(windowFrame: windowFrame, offset: lastYComputed)
        }
        
        let activeScreen = action == .move ? NSScreen.mouse : windowFrame.findScreen()
        if let activeScreen = activeScreen {
            let maxX = activeScreen.visibleFrame.maxX
            
            if positionX > maxX - ExternalTetheredButton.containerWidth {
                positionX = maxX - ExternalTetheredButton.containerWidth
            }
            
            let minY = activeScreen.visibleFrame.minY
            if positionY < minY {
                positionY = minY
            }
        }

        if let state = tetherButtonPanelState {
            state.tetheredButtonYPosition = windowFrame.height -
                (positionY - windowFrame.minY) -
                ExternalTetheredButton.containerHeight + (TetheredButton.height / 2)
        }

        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
    }
    
    private func tetheredWindowMoved(y: CGFloat) {
        guard let trackedWindow = state.foregroundWindow,
              var windowFrame = trackedWindow.element.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }
    
        if trackedWindow.element.isDesktopFinder {
            windowFrame = windowFrame.findScreen()?.visibleFrame ?? windowFrame
        }
        
        let lastYComputed = computeTetheredWindowY(windowFrame: windowFrame, offset: y)
        tetherHintDetails.lastYComputed = lastYComputed
        
        if let state = tetherButtonPanelState {
            state.tetheredButtonYPosition = windowFrame.height -
                (lastYComputed - windowFrame.minY) -
                ExternalTetheredButton.containerHeight + (TetheredButton.height / 2)
        }

        let frame = NSRect(
            x: tetherHintDetails.tetherWindow.frame.origin.x,
            y: lastYComputed,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherHintDetails.tetherWindow.setFrame(frame, display: true)
    }
    
    private func computeTetheredWindowY(windowFrame: NSRect, offset: CGFloat?) -> CGFloat {
        let maxY = windowFrame.maxY - ExternalTetheredButton.containerHeight
        let minY = windowFrame.minY

        var lastYComputed = tetherHintDetails.lastYComputed ?? windowFrame.minY + (windowFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)

        if let offset = offset {
            lastYComputed -= offset
        }

        let finalOffset: CGFloat

        if lastYComputed > maxY {
            finalOffset = maxY
        } else if lastYComputed < minY {
            finalOffset = minY
        } else {
            finalOffset = lastYComputed
        }

        return finalOffset
    }
}

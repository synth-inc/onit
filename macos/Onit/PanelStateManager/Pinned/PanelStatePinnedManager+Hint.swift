//
//  PanelStatePinnedManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 12/05/2025.
//

import Foundation
import SwiftUI

extension PanelStatePinnedManager {
    
    func debouncedShowTetherWindow(activeScreen: NSScreen) {
        hideTetherWindow()

        tetherHintDetails.showTetherDebounceTimer?.invalidate()
        tetherHintDetails.showTetherDebounceTimer = Timer.scheduledTimer(
            withTimeInterval: tetherHintDetails.showTetherDebounceDelay,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showTetherWindow(activeScreen: activeScreen)
            }
        }
    }

    private func showTetherWindow(activeScreen: NSScreen) {
         let tetherView = ExternalTetheredButton(
            onClick: { [weak self] in
                self?.tetherHintClicked(screen: activeScreen)
            },
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
         ).environment(\.windowState, state)

        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherHintDetails.lastYComputed = nil
        tetherButtonPanelState = state

        updateTetherWindowPosition(for: activeScreen, lastYComputed: tetherHintDetails.lastYComputed)
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func tetherHintClicked(screen: NSScreen) {
        hideTetherWindow()
        
        if state.panelOpened {
            resetFramesOnAppChange()
            state.trackedScreen = screen
            state.showPanelForScreen()
        } else {
            state.trackedScreen = screen
            state.launchPanel()
        }
        
        resizeWindows(for: screen)
    }
    
    private func updateTetherWindowPosition(for screen: NSScreen, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - ExternalTetheredButton.containerWidth
        let positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        
        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
    }

    private func tetheredWindowMoved(y: CGFloat) {
        if let tetherPanelState = tetherButtonPanelState,
           let screen = tetherPanelState.trackedScreen {
            if tetherPanelState.panelOpened {
                tetherPanelState.closePanel()
            } else {
                tetherPanelState.launchPanel()
            }
        }
    }
}

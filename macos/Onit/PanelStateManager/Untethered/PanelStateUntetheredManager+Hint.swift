//
//  PanelStateUntetheredManager+Hint.swift
//  Onit
//
//  Created by Kévin Naudin on 13/05/2025.
//

import AppKit
import Defaults
import SwiftUI

extension PanelStateUntetheredManager {
    private var shouldShowOnboarding: Bool {
        let accessibilityNotGranted = AccessibilityPermissionManager.shared.accessibilityPermissionStatus != .granted
        return accessibilityNotGranted && Defaults[.showOnboardingAccessibility]
    }
    
    func debouncedShowTetherWindow(state: OnitPanelState, activeScreen: NSScreen) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeScreen)

        tetherHintDetails.showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: tetherHintDetails.showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showTetherWindow(state: pendingTetherWindow.0, activeScreen: pendingTetherWindow.1)
            }
        }
    }

    private func showTetherWindow(state: OnitPanelState, activeScreen: NSScreen) {
         let tetherView = ExternalTetheredButton(
            onClick: {
                PanelStateCoordinator.shared.launchPanel(for: state)
            },
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(screen: activeScreen, y: translation)
            }
         ).environment(\.windowState, state)

        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherButtonPanelState = state

        if shouldShowOnboarding {
            let tutorialView = TetherTutorialOverlay()
            tutorialWindow.contentView = NSHostingView(rootView: tutorialView)
            tutorialWindow.orderFrontRegardless()
        }

        updateTetherWindowPosition(for: activeScreen, lastYComputed: tetherHintDetails.lastYComputed)
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func updateTetherWindowPosition(for screen: NSScreen, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - ExternalTetheredButton.containerWidth
        var positionY: CGFloat
        let screenKey = screenKey(for: screen)
		
        if let relativePosition = hintYRelativePositionsByScreen[screenKey] {
            positionY = activeScreenFrame.minY + (relativePosition * activeScreenFrame.height) - (ExternalTetheredButton.containerHeight / 2)
            positionY = max(activeScreenFrame.minY, min(positionY, activeScreenFrame.maxY - ExternalTetheredButton.containerHeight))
            
            if let state = tetherButtonPanelState {
                state.tetheredButtonYRelativePosition = relativePosition
            }
        } else {
            positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        }
        
        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
        
        if shouldShowOnboarding {
            let tutorialFrame = NSRect(
                x: positionX - (TetherTutorialOverlay.width) + (ExternalTetheredButton.containerWidth / 2),
                y: positionY + (ExternalTetheredButton.containerHeight / 2) - ((TetherTutorialOverlay.height * 1.5) / 2),
                width: (TetherTutorialOverlay.width * 1.5),
                height: (TetherTutorialOverlay.height * 1.5)
            )
            tutorialWindow.setFrame(tutorialFrame, display: false)
        }
    }
    
    private func computeHintYPosition(for screenVisibleFrame: CGRect, offset: CGFloat?) -> CGFloat {
        let maxY = screenVisibleFrame.maxY - ExternalTetheredButton.containerHeight
        let minY = screenVisibleFrame.minY

        var lastYComputed = tetherHintDetails.lastYComputed ?? screenVisibleFrame.minY + (screenVisibleFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)

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

    private func tetheredWindowMoved(screen: NSScreen, y: CGFloat) {
        let screenFrame = screen.visibleFrame
        let lastYComputed = computeHintYPosition(for: screenFrame, offset: y)
        
        tetherHintDetails.lastYComputed = lastYComputed
        
        let relativeY = (lastYComputed + (ExternalTetheredButton.containerHeight / 2) - screenFrame.minY) / screenFrame.height
        let screenKey = screenKey(for: screen)
        
        hintYRelativePositionsByScreen[screenKey] = max(0.0, min(1.0, relativeY))
        tetherButtonPanelState?.tetheredButtonYRelativePosition = hintYRelativePositionsByScreen[screenKey]

        let frame = NSRect(
            x: tetherHintDetails.tetherWindow.frame.origin.x,
            y: lastYComputed,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherHintDetails.tetherWindow.setFrame(frame, display: true)
        
        if shouldShowOnboarding {
            let positionX = screenFrame.maxX - ExternalTetheredButton.containerWidth
            let tutorialFrame = NSRect(
                x: positionX - (TetherTutorialOverlay.width) + (ExternalTetheredButton.containerWidth / 2),
                y: lastYComputed + (ExternalTetheredButton.containerHeight / 2) - ((TetherTutorialOverlay.height * 1.5) / 2),
                width: (TetherTutorialOverlay.width * 1.5),
                height: (TetherTutorialOverlay.height * 1.5)
            )
            tutorialWindow.setFrame(tutorialFrame, display: true)
        }
    }

	private func screenKey(for screen: NSScreen) -> String {
        return "\(screen.frame.origin.x)-\(screen.frame.origin.y)-\(screen.frame.width)-\(screen.frame.height)"
    }
}

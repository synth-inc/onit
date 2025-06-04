//
//  PanelStateConventionalManager+Hint.swift
//  Onit
//
//  Created by Codex on 2024-06-01.
//

import SwiftUI

extension PanelStateConventionalManager {
    func debouncedShowTetherWindow(activeScreen: NSScreen) {
        hideTetherWindow()

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
                self?.tetheredWindowMoved(screen: activeScreen, y: translation)
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
        state.trackedScreen = screen
        launchPanel(for: state)
    }

    private func updateTetherWindowPosition(for screen: NSScreen, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - ExternalTetheredButton.containerWidth
        var positionY: CGFloat

        if lastYComputed == nil {
            positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        } else {
            positionY = computeHintYPosition(for: activeScreenFrame, offset: lastYComputed)
        }

        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
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

        if let state = tetherButtonPanelState {
            state.tetheredButtonYPosition = screenFrame.height -
                (lastYComputed - screenFrame.minY) -
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
}

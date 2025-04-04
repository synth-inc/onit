//
//  TetherAppsManager+Animation.swift
//  Onit
//
//  Created by Kévin Naudin on 03/04/2025.
//

import ApplicationServices
import SwiftUI

extension TetherAppsManager {
    func animateEnter(
        activeWindow: AXUIElement,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        fromPanel: CGRect,
        toPanel: CGRect
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        panel.setFrame(fromPanel, display: false)
        panel.alphaValue = 0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(toPanel, display: false)
            panel.animator().alphaValue = 1
        } completionHandler: {
            panel.isAnimating = false
            
            if let toActive = toActive {
                _ = activeWindow.setFrame(toActive)
            }
        }
    }
    
    func animateExit(
        windowState: ActiveWindowState?,
        activeWindow: AXUIElement,
        fromActive: CGRect,
        toActive: CGRect,
        panel: OnitPanel? = nil,
        fromPanel: CGRect? = nil,
        toPanel: CGRect? = nil,
        steps: Int = 10,
        duration: TimeInterval = 0.2
    ) {
        _ = activeWindow.setFrame(toActive)
        
        if let panel = panel, let fromPanel = fromPanel, let toPanel = toPanel {
            guard !panel.isAnimating, panel.frame != toPanel else { return }
            
            panel.isAnimating = true
            panel.setFrame(fromPanel, display: false)
            panel.alphaValue = 1
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                
                panel.animator().setFrame(toPanel, display: false)
                panel.animator().alphaValue = 0
            } completionHandler: {
                panel.hide()
                panel.isAnimating = false
                
                if let windowState = windowState {
                    self.showTetherWindow(windowState: windowState, activeWindow: activeWindow)
                    windowState.state.panel = nil
                }
                
                self.targetInitialFrames.removeValue(forKey: activeWindow)
                OnitPanelManager.shared.updateLevelState(elementIdentifier: activeWindow.identifier())
            }
        }
    }
}

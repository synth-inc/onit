//
//  TetherAppsManager+Animation.swift
//  Onit
//
//  Created by Kévin Naudin on 03/04/2025.
//

import ApplicationServices
import SwiftUI

extension TetherAppsManager {
    private func easeInOutCubic(_ t: Double) -> Double {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    func animateEnter(
        activeWindow: AXUIElement,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        fromPanel: CGRect,
        toPanel: CGRect,
        steps: Int = 10,
        duration: TimeInterval = 0.2
    ) {
        let activeWindowPid = activeWindow.pid()
        let stepDuration = duration / TimeInterval(steps)
        
        if let pid = activeWindowPid {
            animationTasks[pid]?.cancel()
        }
        
        let task = Task { @MainActor in
            for step in 0...steps {
                if Task.isCancelled { break }
                
                let progress = Double(step) / Double(steps)
                let easedProgress = easeInOutCubic(progress)
                
                if let fromActive = fromActive, let toActive = toActive {
                    let currentActiveWidth = fromActive.width + (toActive.width - fromActive.width) * easedProgress
                    let currentActiveHeight = fromActive.height + (toActive.height - fromActive.height) * easedProgress
                    let currentActiveX = fromActive.origin.x + (toActive.origin.x - fromActive.origin.x) * easedProgress
                    let currentActiveY = fromActive.origin.y + (toActive.origin.y - fromActive.origin.y) * easedProgress
                    let currentActiveFrame = CGRect(
                        x: currentActiveX,
                        y: currentActiveY,
                        width: currentActiveWidth,
                        height: currentActiveHeight
                    )
                    
                    _ = activeWindow.setFrame(currentActiveFrame)
                }
                
                let currentPanelWidth = fromPanel.width + (toPanel.width - fromPanel.width) * easedProgress
                let currentPanelHeight = fromPanel.height + (toPanel.height - fromPanel.height) * easedProgress
                let currentPanelX = fromPanel.origin.x + (toPanel.origin.x - fromPanel.origin.x) * easedProgress
                let currentPanelY = fromPanel.origin.y + (toPanel.origin.y - fromPanel.origin.y) * easedProgress
                let currentPanelFrame = NSRect(
                    x: currentPanelX,
                    y: currentPanelY,
                    width: currentPanelWidth,
                    height: currentPanelHeight
                )
                
                panel.setFrame(currentPanelFrame, display: true, animate: false)
                //panel.alphaValue = easedProgress
                
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
            
            if let pid = activeWindowPid {
                animationTasks.removeValue(forKey: pid)
            }
        }
        
        if let pid = activeWindowPid {
            animationTasks[pid] = task
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
        let activeWindowPid = activeWindow.pid()
        let stepDuration = duration / TimeInterval(steps)
        
        if let pid = activeWindowPid {
            animationTasks[pid]?.cancel()
        }
        
        let task = Task { @MainActor in
            for step in 0...steps {
                if Task.isCancelled { break }
                
                let progress = Double(step) / Double(steps)
                let easedProgress = easeInOutCubic(progress)
                
                let currentActiveWidth = fromActive.width + (toActive.width - fromActive.width) * easedProgress
                let currentActiveHeight = fromActive.height + (toActive.height - fromActive.height) * easedProgress
                let currentActiveX = fromActive.origin.x + (toActive.origin.x - fromActive.origin.x) * easedProgress
                let currentActiveY = fromActive.origin.y + (toActive.origin.y - fromActive.origin.y) * easedProgress
                let currentActiveFrame = CGRect(
                    x: currentActiveX,
                    y: currentActiveY,
                    width: currentActiveWidth,
                    height: currentActiveHeight
                )
                
                _ = activeWindow.setFrame(currentActiveFrame)
                
                if let panel = panel, let fromPanel = fromPanel, let toPanel = toPanel {
                    let currentPanelWidth = fromPanel.width + (toPanel.width - fromPanel.width) * easedProgress
                    let currentPanelHeight = fromPanel.height + (toPanel.height - fromPanel.height) * easedProgress
                    let currentPanelX = fromPanel.origin.x + (toPanel.origin.x - fromPanel.origin.x) * easedProgress
                    let currentPanelY = fromPanel.origin.y + (toPanel.origin.y - fromPanel.origin.y) * easedProgress
                    let currentPanelFrame = NSRect(
                        x: currentPanelX,
                        y: currentPanelY,
                        width: currentPanelWidth,
                        height: currentPanelHeight
                    )
                    
                    panel.setFrame(currentPanelFrame, display: true, animate: false)
                    panel.alphaValue = 1 - easedProgress
                }
                
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                updateTetherWindowPosition(for: activeWindow)
            }
            
            panel?.hide()
            
            if let windowState = windowState {
                showTetherWindow(windowState: windowState, activeWindow: activeWindow)
                windowState.state.panel = nil
            }
            
            if let pid = activeWindowPid {
                animationTasks.removeValue(forKey: pid)
                targetInitialFrames.removeValue(forKey: pid)
            }
        }
        
        if let pid = activeWindowPid {
            animationTasks[pid] = task
        }
    }
}

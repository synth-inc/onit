//
//  OnitPanelState+NSWindowDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 16/05/2025.
//

import AppKit

extension OnitPanelState: NSWindowDelegate {
    
    func windowDidBecomeKey(_ notification: Notification) {
        notifyDelegates { $0.panelBecomeKey(state: self) }
    }

    func windowWillMiniaturize(_ notification: Notification) {
        if !panelMiniaturized {
            panelMiniaturized = true
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        if panelMiniaturized {
            panelMiniaturized = false
        }
    }
}

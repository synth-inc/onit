//
//

import Foundation
import AppKit

extension OnitPanelState {
    var isScreenMode: Bool {
        return trackedWindow == nil && trackedScreen != nil
    }
    
    func shouldRepositionPanel(action: TrackedWindowAction) -> Bool {
        return !isScreenMode
    }
    
    func animateEnter(
        activeWindow: AXUIElement?,
        fromActive: CGRect?,
        toActive: CGRect?,
        panel: OnitPanel,
        fromPanel: CGRect,
        toPanel: CGRect
    ) {
        guard !panel.isAnimating, panel.frame != toPanel else { return }
        
        panel.isAnimating = true
        panel.setFrame(fromPanel, display: false)
        panel.alphaValue = 1
        
        self.animateChatView = true
        self.showChatView = false
        
        panel.setFrame(toPanel, display: true)
        self.animateChatView = true
        self.showChatView = true
        panel.isAnimating = false
        panel.wasAnimated = true
    }
}

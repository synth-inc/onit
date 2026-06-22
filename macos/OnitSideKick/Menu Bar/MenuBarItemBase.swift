//
//  MenuBarItemBase.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit

class MenuBarItemBase: NSMenuItem {
    // MARK: - Initializers
    
    override init(
        title string: String,
        action selector: Selector?,
        keyEquivalent charCode: String
    ) {
        super.init(
            title: string,
            action: selector,
            keyEquivalent: charCode
        )
        
        self.initializeProperties()
    }
    
    /// Vestigial boilerplate, as NSMenuItem must conform to NSCoding.
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        #if DEBUG
        log.error("\(Self.self) - init(coder:) has not been implemented. This item will not render in the menu bar UI.")
        #endif
        
        /// If the menu item somehow fails to implement the coder, don't show it in the UI:
        self.isHidden = true
        self.isEnabled = false
        self.target = nil
        self.action = nil
    }
    
    // MARK: - Lifecycle Functions
    
    /// Subclasses should override this method to configure their custom properties.
    /// e.g. `title`, `action`, `keyEquivalent`, `target`, `isEnabled`, etc.
    func initializeProperties() { }
    
    /// Subclasses should override this method to configure post-launch setup.
    /// This is a workround to get main actor tasks (among others) to run in NSMenuItem's nonisolated initialization context.
    @MainActor
    func runPostInitilizationSetup() { }
    
    // MARK: - Helper Functions
    
    func drawStatusDot(_ color: NSColor) -> NSImage {
        let image = NSImage(
            size: NSSize(width: 6, height: 6),
            flipped: false
        ) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        
        image.isTemplate = false /// Prevent AppKit theme-based auto-tinting from interfering with dot color.
        
        return image
    }
}

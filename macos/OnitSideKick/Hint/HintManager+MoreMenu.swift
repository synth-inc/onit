//
//  HintManager+MoreMenu.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions
 * Private Functions
 */

import SwiftUI

extension HintManager {
    // MARK: - Public Functions
    
    func showMoreMenu<SwiftUIView: View>(swiftUIView: SwiftUIView) {
        guard hintWindowIsVisible else { return }

        createMoreMenuWindowIfNeeded()

        guard let moreMenuWindow = self.moreMenuWindow else { return }

        /// Inject the SwiftUI view first so that we can measure the size.
        let hostingView = OnitHostingView(rootView: swiftUIView)
        moreMenuWindow.contentView = hostingView
        
        /// Initial positioning.
        repositionMoreMenuIfNeeded(
            shouldAnimateIn: true,
            isInitialShow: true
        )
    }

    func hideMoreMenu() {
        moreMenuWindow?.orderOut(nil)
        moreMenuWindow?.contentView = nil
    }
    
    // MARK: - Private Functions
    
    private func createMoreMenuWindowIfNeeded() {
        if moreMenuWindow == nil {
            class CustomPanel: NSPanel {
                override var canBecomeKey: Bool { false }
                override var canBecomeMain: Bool { false }
            }
            
            let window = CustomPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.level = .floating
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hidesOnDeactivate = false
            window.isReleasedWhenClosed = false
            
            moreMenuWindow = window
        }
    }
}

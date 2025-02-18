//
//  HighlightHintWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import Defaults
import Foundation
import SwiftUI

enum HighlightHintMode: String, Codable, Defaults.Serializable {
    case none
    case textfield
    case topRight
}

@MainActor
class HighlightHintWindowController {

    // MARK: - Singleton instance

    static let shared = HighlightHintWindowController()

    // MARK: - Private properties

    private let window: NSWindow

    private let staticHostingController = NSHostingController(rootView: StaticPromptView())

    private let onitHostingController = NSHostingController(rootView: OnitPromptView())

    private var mode: HighlightHintMode = FeatureFlagManager.shared.highlightHintMode

    private var uiElementBound: CGRect?

    // MARK: - Initializers

    private init() {
        switch mode {
        case .textfield:
            window = NSWindow(contentViewController: onitHostingController)
        case .topRight:
            window = NSWindow(contentViewController: staticHostingController)
        case .none:
            window = NSWindow()
        }

        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    // MARK: - Functions

    /** Show the open app's shortcut window */
    func show(_ bound: CGRect?) {
        uiElementBound = bound

        guard mode != .none else { return }

        if mode == .topRight && window.isVisible {
            return
        }

        adjustWindow()
        showWindowWithAnimation()
    }

    /** Hide the open app's shortcut window */
    func hide() {
        window.orderOut(nil)
    }

    func isVisible() -> Bool {
        return window.isVisible
    }

    func changeMode(_ mode: HighlightHintMode) {
        self.mode = mode

        switch mode {
        case .topRight:
            window.contentViewController = staticHostingController
            break

        case .textfield:
            window.contentViewController = onitHostingController

        case .none:
            window.contentViewController = nil
            return
        }

        adjustWindow()
    }

    func adjustWindow() {
        DispatchQueue.main.async {
            guard let currentScreen = NSScreen.main else {
                print("No main screen found.")
                return
            }

            switch self.mode {
            case .topRight:
                // Get the window's height (or 75x75 beacuse sometimes it's empty?)
                let windowHeight = max(self.window.frame.height, 75)
                let windowWidth = max(self.window.frame.width, 75)

                // Calculate the new origin for the window to be at the top right corner of the current screen
                let newOriginX = currentScreen.visibleFrame.maxX - (windowWidth - 10)
                let newOriginY = currentScreen.visibleFrame.maxY - (windowHeight + 85)

                // Set the window's position to the calculated top right corner
                self.window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))

            case .textfield:
                // TODO: KNA - Filter if uiElementBound weird (origin minY = maxY)
                if let bound = self.uiElementBound {
                    let elementScreenY = currentScreen.frame.height - bound.origin.y

                    let newOriginX = bound.origin.x
                    let newOriginY = elementScreenY + 0

                    self.window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
                } else {
                    // TODO: KNA - What to do
                }

            case .none:
                break
            }
        }
    }

    private func showWindowWithAnimation() {
        DispatchQueue.main.async {
            guard let screen = NSScreen.main else { return }

            let screenFrame = screen.frame
            var windowFrame = self.window.frame

            switch self.mode {
            case .topRight:
                // Set initial position (not visible)
                windowFrame.origin.x = screenFrame.maxX
                self.window.setFrame(windowFrame, display: false)
                self.window.alphaValue = 0
                self.window.makeKeyAndOrderFront(nil)

                // Set initial position (visible)
                windowFrame.origin.x = screenFrame.maxX - windowFrame.width

                // Apply animation
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.window.animator().setFrame(windowFrame, display: true)
                    self.window.animator().alphaValue = 1.0
                }

            case .textfield:
                self.window.alphaValue = 0
                self.window.makeKeyAndOrderFront(nil)

                // Apply animation
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.window.animator().alphaValue = 1.0
                }

            case .none:
                break
            }
        }
    }

    func shortcutChanges(empty: Bool) {
        guard !empty else {
            // hide()
            print("Prompt hide")
            return
        }

        //        let hostingController = mode == .topRight ?
        //            NSHostingController(rootView: StaticPromptView()) :
        //            NSHostingController(rootView: OnitPromptView())
        //
        //        window.contentViewController = hostingController

        // window.orderFront(nil)
        // adjustWindow()
        print("Prompt reset with new view content.")
    }
    
}

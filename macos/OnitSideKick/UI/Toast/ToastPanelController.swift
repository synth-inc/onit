//
//  ToastPanelController.swift
//  Onit
//
//  Created by Loyd Kim on 5/21/26.
//

import AppKit
import SwiftUI

@MainActor
final class ToastPanelController {
    // MARK: - Singleton

    static let shared = ToastPanelController()

    // MARK: - Initializer

    private init() {}

    // MARK: - Private States

    private var panel: NSPanel? = nil
    private var hostingController: NSHostingController<ToastPanelView>? = nil
    private var hideTask: Task<Void, Never>? = nil
    
    // MARK: - Private Variables

    private let animationDuration: TimeInterval = 0.2
    private let slideOffset: CGFloat = 20
    private let bottomInset: CGFloat = 8

    // MARK: - Public Functions

    func show(
        message: String,
        duration: TimeInterval = 2.0,
        sizeConfigs: ToastPanelView.SizeConfigs = .init()
    ) {
        tearDownPanel()

        let toastViewHost = setupToastViewHost(with: message, sizeConfigs)
        let toastPanel = setupToastPanel(with: toastViewHost)
        let containerWindowFrame = resolveContainerWindowFrame()

        let toastPanelSize = toastPanel.frame.size

        let finalAnimatedPosition = NSPoint(
            x: containerWindowFrame.midX - toastPanelSize.width / 2,
            y: containerWindowFrame.minY + bottomInset
        )
        let startingAnimatedPosition = NSPoint(
            x: finalAnimatedPosition.x,
            y: finalAnimatedPosition.y - slideOffset
        )
        let finalAnimatedFrame = NSRect(
            origin: finalAnimatedPosition,
            size: toastPanelSize
        )

        toastPanel.setFrameOrigin(startingAnimatedPosition) /// Start the fade-in animation at a slight offset for the slide-in effect.
        toastPanel.alphaValue = 0 /// Start at invisible opacity for the fade-in animation.
        toastPanel.orderFrontRegardless() /// Avoids stealing key-window status from whatever the user was interacting with.

        self.panel = toastPanel
        self.hostingController = toastViewHost

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            toastPanel.animator().alphaValue = 1.0
            toastPanel.animator().setFrame(finalAnimatedFrame, display: true)
        })

        /// Capture the panel weakly so we can verify it's still the current toast before firing `hide()`.
        /// If `show()` has installed a fresh panel since this task was scheduled, calling `hide()` here would cancel the new toast's own auto-dismiss timer (via `hideTask?.cancel()` inside `hide()`) and leave it stuck on screen.
        hideTask = Task { [weak self, weak toastPanel] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self,
                      let toastPanel,
                      self.panel === toastPanel
                else {
                    return
                }

                self.hide()
            }
        }
    }

    func hide() {
        guard let panelBeingHidden = panel else { return }

        hideTask?.cancel()
        hideTask = nil

        let currentFrame = panelBeingHidden.frame

        let finalAnimatedFrame = NSRect(
            origin: NSPoint(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y - slideOffset
            ),
            size: currentFrame.size
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panelBeingHidden.animator().alphaValue = 0
            panelBeingHidden.animator().setFrame(finalAnimatedFrame, display: true)
        }, completionHandler: { [weak self] in
            /// Only tear down if a new `show()` hasn't replaced the panel since this animation started.
            /// Otherwise, we'd `orderOut` the freshly-shown toast.
            guard let self,
                  self.panel === panelBeingHidden
            else {
                return
            }
            
            self.tearDownPanel()
        })
    }

    // MARK: - Private Functions: Tear Down Panel

    private func tearDownPanel() {
        hideTask?.cancel()
        hideTask = nil
        
        panel?.orderOut(nil)
        panel = nil
        
        hostingController = nil
    }
    
    // MARK: - Private Functions: Setup Toast View Host
    
    private func setupToastViewHost(
        with message: String,
        _ sizeConfigs: ToastPanelView.SizeConfigs
    ) -> NSHostingController<ToastPanelView> {
        let toastView = ToastPanelView(
            message: message,
            sizeConfigs: sizeConfigs,
            dismissAction: { [weak self] in
                guard let self else { return }
                self.hide()
            }
        )
        
        let toastViewHost = NSHostingController(rootView: toastView)

        return toastViewHost
    }

    // MARK: - Private Functions: Setup Toast Panel

    private func setupToastPanel(with toastViewHost: NSHostingController<ToastPanelView>) -> NSPanel {
        let toastPanel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        toastPanel.contentViewController = toastViewHost
        configureToastPanel(for: toastPanel)

        /// Lay the SwiftUI content out against an effectively unconstrained width before measuring.
        /// This allows long messages to report their full intrinsic width, rather than a width-compressed (truncated) size.
        let unconstrainedWidth: CGFloat = 10_000
        toastViewHost.view.setFrameSize(NSSize(width: unconstrainedWidth, height: unconstrainedWidth))
        toastViewHost.view.layoutSubtreeIfNeeded()
        toastPanel.setContentSize(toastViewHost.view.fittingSize)

        return toastPanel
    }

    private func configureToastPanel(for toastPanel: NSPanel) {
        toastPanel.isOpaque = false
        toastPanel.backgroundColor = .clear
        toastPanel.hasShadow = false
        toastPanel.level = .floating
        toastPanel.worksWhenModal = true
        toastPanel.collectionBehavior = [
            .transient,
            .ignoresCycle
        ]
    }
    
    // MARK: - Private Functions: Resolve Container Window Frame

    /// Resolves the frame of the container window the toast should be bottom-centered against.
    /// Always returns a top-level app window — never a sheet or auxiliary panel —
    /// so the toast appears at the bottom of the app window rather than inside
    /// whatever modal currently owns the focus.
    private func resolveContainerWindowFrame() -> NSRect {
        if let mainWindow = NSApp.mainWindow, isAppWindow(mainWindow) {
            return mainWindow.frame
        }

        if let keyWindow = NSApp.keyWindow, isAppWindow(keyWindow) {
            return keyWindow.frame
        }

        if let appWindow = NSApp.windows.first(where: { isAppWindow($0) }) {
            return appWindow.frame
        }

        return NSScreen.main?.visibleFrame ?? .zero
    }

    /// Whether `window` is a real top-level app window suitable for anchoring a toast.
    /// Sheets and `NSPanel`s (including our own toast panels and popovers) are excluded so the toast cannot get pinned to a modal sheet's frame.
    private func isAppWindow(_ window: NSWindow) -> Bool {
        return window.isVisible
            && !window.isSheet
            && !(window is NSPanel)
            && window.styleMask.contains(.titled)
    }
}

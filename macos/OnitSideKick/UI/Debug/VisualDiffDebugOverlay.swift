//
//  VisualDiffDebugOverlay.swift
//  Onit
//
//  Created by Timothy Lenardo on 9/10/25.
//

import AppKit
import Foundation
import Defaults

@MainActor
final class VisualDiffDebugOverlay {
    static let shared = VisualDiffDebugOverlay()
    private var window: NSWindow?
    private var overlayView: VisualDiffDebugOverlayView?
    private let fadeDuration: TimeInterval = 0.5
    private var fadeSequenceId: UInt = 0
    private var delayTask: Task<Void, Never>?

    private init() {}

    func show(at: CGRect, rects: [CGRect], duration: TimeInterval = 0.0) {
        // Only show overlay if the debug setting is enabled
        // guard Defaults[.showVisualDiffDebugOverlay] else { return }
        // guard let screen = NSScreen.primary ?? NSScreen.main else { return }

        // Cancel any pending delay task
        delayTask?.cancel()

        if window == nil {
            let styleMask: NSWindow.StyleMask = [.borderless]
            let w = NSWindow(
                contentRect: at,
                styleMask: styleMask,
                backing: .buffered,
                defer: false
                // screen: screen
            )
            w.level = .floating
            w.isReleasedWhenClosed = false
            w.ignoresMouseEvents = true
            w.backgroundColor = .clear
            w.isOpaque = false
            w.collectionBehavior = [.canJoinAllSpaces, .stationary]
            w.animationBehavior = .none

            let v = VisualDiffDebugOverlayView(frame: at)
            v.autoresizingMask = [.width, .height]
            w.contentView = v
            window = w
            overlayView = v
        }

        // Ensure the window covers the screen (in case of resolution change)
        if window?.frame != at {
            window?.setFrame(at, display: true)
        }

        // Cancel any in-flight fade by resetting alpha immediately and bumping the sequence id
        fadeSequenceId &+= 1
        if let w = window {
            w.alphaValue = 1.0
        }

        overlayView?.update(rects: rects)
        window?.orderFront(nil)

        // If duration > 0, wait before starting fade; otherwise fade immediately
        if duration > 0 {
            let currentSequenceId = fadeSequenceId
            delayTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled, self.fadeSequenceId == currentSequenceId else { return }
                self.startFadeOut(sequenceId: currentSequenceId)
            }
        } else {
            // Start fade-out animation immediately; on completion remove from hierarchy if still current
            startFadeOut(sequenceId: fadeSequenceId)
        }
    }

    func hide() {
        // Cancel any in-flight fade and remove immediately
        fadeSequenceId &+= 1
        overlayView?.update(rects: [])
        if let w = window {
            w.alphaValue = 0
            w.orderOut(nil)
        }
        overlayView = nil
        window = nil
    }

    private func startFadeOut(sequenceId: UInt) {
        guard let w = window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            w.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self else { return }
            // If a new show() happened during animation, skip removal
            guard self.fadeSequenceId == sequenceId else { return }
            self.overlayView?.update(rects: [])
            self.window?.orderOut(nil)
            self.overlayView = nil
            self.window = nil
        }
    }
}

final class VisualDiffDebugOverlayView: NSView {
    private var rects: [CGRect] = []

    override var isOpaque: Bool { false }

    func update(rects: [CGRect]) {
        self.rects = rects
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Clear the entire view to transparent
        NSColor.clear.setFill()
        bounds.fill()

        // Colors for different rects
        let colors: [NSColor] = [
            NSColor.red.withAlphaComponent(0.3),    // Search region (red)
            NSColor.blue.withAlphaComponent(0.4),   // New position (blue)
            NSColor.green.withAlphaComponent(0.4)   // Last position (green)
        ]

        print("debugDiffView - new rects \(rects.count)")
        for (index, r) in rects.enumerated() {
            print("debugDiffView - drawing Rect[\(index)]: \(r)")
            let converted = CGRect(x: r.origin.x, y: r.origin.y, width: r.width, height: r.height)
            let color = colors[index % colors.count]
            color.setFill()
            converted.fill()
        }
    }
}

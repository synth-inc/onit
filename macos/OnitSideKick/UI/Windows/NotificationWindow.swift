//
//  NotificationWindow.swift
//  Onit
//
//  Created by Loyd Kim on 10/6/25.
//

import SwiftUI

struct NotificationWindowAnimation {
    enum Direction {
        case up
        case right
        case down
        case left
    }
    
    let direction: Direction
    let offset: CGFloat
    let duration: TimeInterval?
    
    init(
        direction: Direction,
        offset: CGFloat = 40,
        duration: TimeInterval? = nil
    ) {
        self.direction = direction
        self.offset = offset
        self.duration = duration
    }
}

@MainActor
final class NotificationWindow: NonActivatingPanel {
    // MARK: - Properties
    
    let createdAt: Date
    let namedIdentifier: String?
    let enterAnimation: NotificationWindowAnimation?
    let dismissAnimation: NotificationWindowAnimation?
    
    private var hostingController: NSHostingController<NotificationWindowView>
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var eventMonitors: [Any] = []
    
    // MARK: - Initializers
    
    init(
        contentRect: NSRect = NSRect(x: 0, y: 0, width: 0, height: 0),
        styleMask: NSWindow.StyleMask = [],
        backing: NSWindow.BackingStoreType = .buffered,
        defer flag: Bool = false,

        titleKey: String,
        captionKey: String? = nil,
        image: ImageResource? = nil,
        primaryAction: NotificationWindowView.Action? = nil,
        secondaryAction: NotificationWindowView.Action? = nil,
        closeButtonCallback: (() -> Void)? = nil,

        namedIdentifier: String? = nil,
        enterAnimation: NotificationWindowAnimation? = nil,
        dismissAnimation: NotificationWindowAnimation? = nil
    ) {
        self.createdAt = Date()
        self.namedIdentifier = namedIdentifier
        self.enterAnimation = enterAnimation
        self.dismissAnimation = dismissAnimation

        self.hostingController = NSHostingController(
            rootView: NotificationWindowView(
                createdAt: self.createdAt,
                titleKey: titleKey,
                captionKey: captionKey,
                image: image,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
                closeButtonCallback: closeButtonCallback
            )
        )

        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: backing,
            defer: flag
        )

        super.setup(addShadow: false)
        self.setupWindow()
    }
    
    // MARK: - States
    
    private var dismissalTask: Task<Void, Never>? = nil
    
    // MARK: - Private Variables
    
    private let xPositionOffset: CGFloat = 24
    private let yPositionOffset: CGFloat = 24
    private let spacingBetweenStackedNotifications: CGFloat = 8
    private let defaultAnimationDuration: TimeInterval = animationDuration * 2
     
    // MARK: - Public Functions
    
    func showNotification() {
        let hostView = self.hostingController.view
        
        hostView.alphaValue = 0.0
        
        self.orderFrontRegardless()
        self.restackNotificationWindows()
        
        let animationFinalFrame = self.frame
        
        /// If the `enterAnimation` property were provided, set the *initial* animation to the offset to add an "animate FROM" effect.
        if let enterAnimation = self.enterAnimation {
            let animationInitialFrame = self.createNewFrameForAnimation(
                from: animationFinalFrame,
                using: enterAnimation
            )
            self.setFrame(animationInitialFrame, display: false)
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = self.enterAnimation?.duration ?? self.defaultAnimationDuration
            hostView.animator().alphaValue = 1.0
            
            /// If an *initial* animation were set, we start at that frame and then animate back to the initial frame position (i.e. `animationFinalFrame`) to add an "animate FROM" effect.
            /// Otherwise, we animate in place.
            self.animator().setFrame(animationFinalFrame, display: false)
        } completionHandler: {
            /// Ensures notifications windows are properly restacked when multiple windows are created concurrently or in quick succession.
            /// Note: The initial restack after `self.orderFrontRegardless()` is required, as it allows us to properly set the positioning for the `animationFinalFrame`.
            Task { @MainActor [weak self] in
                self?.restackNotificationWindows()
            }
        }
    }
    
    func dismissNotification(onComplete: (@MainActor @Sendable () -> Void)? = nil) {
        /// Prevents dismiss spamming by limiting dismiss requests to one per notification window.
        guard self.dismissalTask == nil else { return }
        
        self.dismissalTask = Task { @MainActor in
            let hostView = self.hostingController.view
            
            hostView.alphaValue = 1.0
            
            /// Suspending the removal logic until the animation first completes to ensure smooth transition-out.
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = self.dismissAnimation?.duration ?? self.defaultAnimationDuration
                    hostView.animator().alphaValue = 0.0
                    
                    /// If the `exitAnimation` property were provided, set the *final* animation to the offset to add an "animate TO" effect.
                    /// Otherwise, we animate in place.
                    if let dismissAnimation = self.dismissAnimation {
                        let animationFinalFrame = self.createNewFrameForAnimation(
                            from: self.frame,
                            using: dismissAnimation
                        )
                        self.animator().setFrame(animationFinalFrame, display: false)
                    }
                } completionHandler: {
                    continuation.resume()
                }
            }
            
            self.removeNotification()
            self.close()
            self.restackNotificationWindows()
            
            self.dismissalTask = nil
            
            onComplete?()
        }
    }
    
    // MARK: - Private Functions: Animation
    
    private func createNewFrameForAnimation(
        from referenceFrame: NSRect,
        using animation: NotificationWindowAnimation
    ) -> NSRect {
        var animatedFrame = referenceFrame
        
        let offset = animation.offset
        
        switch animation.direction {
        case .up:
            animatedFrame.origin.y += offset
        case .right:
            animatedFrame.origin.x += offset
        case .down:
            animatedFrame.origin.y -= offset
        case .left:
            animatedFrame.origin.x -= offset
        }
        
        return animatedFrame
    }
    
    // MARK: - Private Functions: Cleanup
    
    private func cleanupObserversAndMonitors() {
        for (notificationCenter, notificationProtocol) in self.observers {
            notificationCenter.removeObserver(notificationProtocol)
        }
        self.observers.removeAll()
        
        for monitor in self.eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        self.eventMonitors.removeAll()
    }
    
    private func removeNotification() {
        self.cleanupObserversAndMonitors()
        self.orderOut(nil)
        self.contentViewController = nil
    }
    
    // MARK: - Private Functions: Positioning
    
    private func updateSize() {
        let hostView = self.hostingController.view
        hostView.layoutSubtreeIfNeeded()
        
        var size = hostView.fittingSize
        if size.width <= 0 || size.height <= 0 {
            size = NSSize(width: 1, height: 1)
        }
        
        self.setContentSize(size)
    }
    
    /// If not `nil`, this will allow the notification window to move to the currently-active screen.
    private static func getScreenContainingMouseCursor() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        
        for screen in NSScreen.screens {
            if screen.frame.contains(mouse) {
                return screen
            }
        }
        
        return nil
    }
    
    private func restackNotificationWindows() {
        guard let screen = Self.getScreenContainingMouseCursor() ?? NSScreen.main
        else { return }
        
        let notificationWindowsSortedByOldestFirst = NSApp.windows
            .compactMap { $0 as? NotificationWindow }
            .filter { $0.isVisible }
            .sorted { $0.createdAt < $1.createdAt }
        
        let visibleFrame = screen.visibleFrame
        let maxX = visibleFrame.maxX
        var maxY = visibleFrame.maxY
        
        for window in notificationWindowsSortedByOldestFirst {
            window.updateSize()
            
            let frameWidth = window.frame.size.width
            
            let xPosition = maxX - window.xPositionOffset - frameWidth
            let yPosition = maxY - window.yPositionOffset
            
            window.setFrameTopLeftPoint(
                NSPoint(
                    x: xPosition,
                    y: yPosition
                )
            )
            
            maxY -= (window.frame.size.height + window.spacingBetweenStackedNotifications)
        }
    }
    
    // MARK: - Private Functions: Setup
    
    private func setupWindow() {
        self.contentViewController = self.hostingController
        
        let hostView = self.hostingController.view
        
        hostView.setContentHuggingPriority(.required, for: .horizontal)
        hostView.setContentHuggingPriority(.required, for: .vertical)
        hostView.postsFrameChangedNotifications = true
        
        self.restackNotificationWindows()
        
        /// Allows the notification window to dynamically update its size and position based on the size of its child.
        let contentSizeObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: hostView,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.restackNotificationWindows()
            }
        }
        self.observers.append((NotificationCenter.default, contentSizeObserver))
        
        /// Allows the notification window to reposition when when external displays are attached/removed.
        let screenParamsObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.restackNotificationWindows()
            }
        }
        self.observers.append((NotificationCenter.default, screenParamsObserver))
        
        /// Allows the notification window to follow the user's active screen, ensuring that it's always within their line of sight.
        let spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.restackNotificationWindows()
            }
        }
        self.observers.append((NSWorkspace.shared.notificationCenter, spaceObserver))

        /// Ensures the notification window moves to the screen the user's mouse clicked into (i.e. when changing "active" screens).
        if let mouseClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown],
            handler: { _ in
                Task { @MainActor [weak self] in
                    self?.restackNotificationWindows()
                }
            }
        ) {
            self.eventMonitors.append(mouseClickMonitor)
        }

        /// Ensures the notification window doesn't leave any lingering processes.
        let terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.cleanupObserversAndMonitors()
            }
        }
        self.observers.append((NotificationCenter.default, terminationObserver))
    }
    
    // MARK: - Overrides
    
    override func close() {
        self.cleanupObserversAndMonitors()
        super.close()
    }
}

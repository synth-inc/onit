//
//  AppDelegate+Accessibility.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import ApplicationServices
import SwiftUI

class Accessibility {
    let kAXFrameAttribute = "AXFrame"

    private var window: NSWindow?

    private var nsObjectObserver: NSObjectProtocol?
    private var observer: AXObserver?

    private init() { }

    private static let shared = Accessibility()

    static func requestPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            print("Requesting Accessibility Permissions...")
        } else {
            print("Accessibility Trusted!")
        }
    }

    @MainActor
    static func setupWindow<Content: View>(withView contentView: Content) {
        shared.setupWindow(withView: contentView)
    }

    @MainActor
    private func setupWindow<Content: View>(withView contentView: Content) {
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    static func observeActiveApplication() {
        shared.observeActiveApplication()
    }

    private func observeActiveApplication() {
        nsObjectObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                print("\nApplication activated: \(app.localizedName ?? "Unknown")")
                self.setupObserver(for: app.processIdentifier)
            }
        }
    }

    private func setupObserver(for pid: pid_t) {
        print("Setting up observer for PID: \(pid)")
        let appElement = AXUIElementCreateApplication(pid)

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            let delegate = Unmanaged<OldAppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
            print("Focus change notification: \(notification)")
            delegate.handleFocusChange(for: element)
        }

        let result = AXObserverCreate(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observer = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()

            AXObserverAddNotification(observer, appElement, kAXFocusedUIElementChangedNotification as CFString, refCon)
            AXObserverAddNotification(observer, appElement, kAXFocusedWindowChangedNotification as CFString, refCon)

            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

            print("Observer registered for PID: \(pid)")

            handleFocusChange(for: appElement)
        } else {
            print("Failed to create observer for PID: \(pid) with result: \(result)")
        }
    }

    func handleFocusChange(for element: AXUIElement) {
        print("Handling focus change...")

        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        if result == .success, let focusedElement = focusedElement {
            print("Focused element found.")

            var frameValue: CFTypeRef?
            let frameResult = AXUIElementCopyAttributeValue(
                focusedElement as! AXUIElement, // swiftlint:disable:this force_cast
                kAXFrameAttribute as CFString,
                &frameValue
            )

            if frameResult == .success, let frameValue = frameValue, CFGetTypeID(frameValue) == AXValueGetTypeID() {
                var frame = CGRect.zero

                AXValueGetValue(frameValue as! AXValue, .cgRect, &frame) // swiftlint:disable:this force_cast
                print("Element frame: \(frame)")

                if let screen = NSScreen.main {
                    print("Screen frame height: \(screen.frame.height)")
                    frame.origin.y = screen.frame.height - frame.origin.y - frame.size.height
                    print("Adjusted frame origin y: \(frame.origin.y)")
                }

                DispatchQueue.main.async {
                    let adjustedY = frame.origin.y + frame.size.height
                    self.window?.setFrameOrigin(NSPoint(x: frame.origin.x, y: adjustedY))
                    print("Floating OmniPromptView moved to above text field position with bottom aligned.")
                }
            }
        }
    }

    func moveFloatingWindowToElement(_ element: AXUIElement) {
        var frameValue: CFTypeRef?
        let frameResult = AXUIElementCopyAttributeValue(element, kAXFrameAttribute as CFString, &frameValue)

        if frameResult == .success, let frameValue = frameValue, CFGetTypeID(frameValue) == AXValueGetTypeID() {
            var frame = CGRect.zero

            AXValueGetValue(frameValue as! AXValue, .cgRect, &frame) // swiftlint:disable:this force_cast
            print("Child element frame before adjustment: \(frame)")

            if let screen = NSScreen.main {
                print("Screen frame height: \(screen.frame.height)")
                frame.origin.y = screen.frame.height - frame.origin.y - frame.size.height
                print("Adjusted child element frame origin y: \(frame.origin.y)")
            }

            DispatchQueue.main.async {
                let adjustedY = frame.origin.y + frame.size.height
                self.window?.setFrameOrigin(NSPoint(x: frame.origin.x, y: adjustedY))
                print("Floating OmniPromptView moved to above child text field position with bottom aligned.")
            }
        } else {
            print("Failed to retrieve the frame of the child element.")
        }
    }

    func findTextFieldInElement(_ element: AXUIElement) -> AXUIElement? {
        var childrenValue: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

        if childrenResult == .success, let children = childrenValue as? [AXUIElement] {
            for child in children {
                var roleValue: CFTypeRef?
                let roleResult = AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleValue)

                if roleResult == .success, let role = roleValue as? String, role == kAXTextFieldRole {
                    return child // Found a text field
                }

                if let nestedChild = findTextFieldInElement(child) {
                    return nestedChild
                }
            }
        }
        return nil
    }
}

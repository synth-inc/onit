//
//  AppDelegate.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Foundation
import ApplicationServices
import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var observer: AXObserver?

    // Define missing AX constants
    let kAXFrameAttribute = "AXFrame"

    func applicationDidFinishLaunching(_ notification: Notification) {
        SMLoginItemSetEnabled("inc.synth.Onit" as CFString, true)

        if let window = NSApplication.shared.windows.first {
            let mouseLocation = NSEvent.mouseLocation

            // Find the screen where the mouse is located
            if let focusedScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
                let screenFrame = focusedScreen.frame
                let windowSize = window.frame.size

                // Set a fixed origin on the current screen where the mouse is located
                let originX: CGFloat = screenFrame.minX + 19
                let originY: CGFloat = screenFrame.maxY - windowSize.height - 34  // Adjust for top-left corner

                // Set the window's position explicitly
                let origin = NSPoint(x: originX, y: originY)
                window.setFrameOrigin(origin)

                // Make sure the window is visible after positioning
                window.makeKeyAndOrderFront(nil)
            }

            // Hide the window buttons (close, minimize, zoom)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Remove the title bar space and make it draggable by the background
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.titled)
            window.styleMask.insert(.fullSizeContentView)

            // Make the window background movable so it can still be dragged
            window.isMovableByWindowBackground = true

            // Restore the window's border radius
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 12 // Set corner radius
        }

        // Ensure accessibility permissions are granted
        requestAccessibilityPermissions()

        // Set up the floating OmniPromptView window
        setupFloatingWindow()

        // Observe when a new app is activated
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func applicationShouldRestoreApplicationState(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // Optional: Terminate the app when the last window is closed
    }

    func requestAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            print("Requesting Accessibility Permissions...")
        } else {
            print("Trusted!")
        }
    }

    func setupFloatingWindow() {
        // Create the NSWindow with SwiftUI OnitPromptView as content
        window = KeyWindow(
            contentRect: NSRect(x: 100, y: 100, width: 200, height: 100), // Adjust size as needed
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Set up NSWindow properties
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.ignoresMouseEvents = false // Ensure the window accepts mouse events
        window?.isMovableByWindowBackground = true
        window?.acceptsMouseMovedEvents = true

        // Embed the SwiftUI view into the window using NSHostingView
        let contentView = NSHostingView(rootView: OnitPromptView())
        contentView.frame = NSRect(x: 0, y: 0, width: 200, height: 100) // Adjust frame size
        window?.contentView = contentView

        // Make the window the key and main window
        window?.makeKeyAndOrderFront(nil)
        window?.makeMain()

        // Assuming 'contentView' contains your text field
        window?.makeFirstResponder(contentView)
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            print("\nApplication activated: \(app.localizedName ?? "Unknown")")
            if let pid = app.processIdentifier as pid_t? {
                // Re-register the observer for the new app
                setupObserver(for: pid)
            }
        }
    }

    func setupObserver(for pid: pid_t) {
        print("Setting up observer for PID: \(pid)")
        let appElement = AXUIElementCreateApplication(pid)

        // Create the observer and register for notifications
        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
            print("Focus change notification: \(notification)")
            delegate.handleFocusChange(for: element)
        }

        let result = AXObserverCreate(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observer = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()

            // Register for focused UI element and window changes in the app
            AXObserverAddNotification(observer, appElement, kAXFocusedUIElementChangedNotification as CFString, refCon)
            AXObserverAddNotification(observer, appElement, kAXFocusedWindowChangedNotification as CFString, refCon)

            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

            print("Observer registered for PID: \(pid)")

            // Immediately check the current focused UI element
            handleFocusChange(for: appElement)
        } else {
            print("Failed to create observer for PID: \(pid) with result: \(result)")
        }
    }

    func handleFocusChange(for element: AXUIElement) {
        print("Handling focus change...")

        // Declare focusedElement as CFTypeRef? (the expected type)
        var focusedElement: CFTypeRef?

        // Retrieve the currently focused element
        let result = AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        if result == .success, let focusedElement = focusedElement {
            print("Focused element found.")

            // Get the frame of the focused element
            var frameValue: CFTypeRef?
            let frameResult = AXUIElementCopyAttributeValue(
                focusedElement as! AXUIElement, // swiftlint:disable:this force_cast
                kAXFrameAttribute as CFString,
                &frameValue
            )

            if frameResult == .success, let frameValue = frameValue, CFGetTypeID(frameValue) == AXValueGetTypeID() {
                var frame = CGRect.zero
                // swiftlint:disable:next force_cast
                AXValueGetValue(frameValue as! AXValue, .cgRect, &frame)
                print("Element frame: \(frame)")

                // Adjust y-coordinate based on screen height
                if let screen = NSScreen.main {
                    print("Screen frame height: \(screen.frame.height)")
                    frame.origin.y = screen.frame.height - frame.origin.y - frame.size.height
                    print("Adjusted frame origin y: \(frame.origin.y)")
                }

                // Move the floating window so that its bottom is at the top of the text field
                DispatchQueue.main.async {
                    // Add the height of the focused element (text field) to the y-coordinate
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
            // swiftlint:disable:next force_cast
            AXValueGetValue(frameValue as! AXValue, .cgRect, &frame)
            print("Child element frame before adjustment: \(frame)")

            // Adjust y-coordinate based on screen height
            if let screen = NSScreen.main {
                print("Screen frame height: \(screen.frame.height)")
                frame.origin.y = screen.frame.height - frame.origin.y - frame.size.height
                print("Adjusted child element frame origin y: \(frame.origin.y)")
            }

            DispatchQueue.main.async {
                // Add the height of the focused element (text field) to the y-coordinate
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

                // Recursively search in child elements
                if let nestedChild = findTextFieldInElement(child) {
                    return nestedChild
                }
            }
        }
        return nil
    }

}

  class KeyWindow: NSWindow {
      override var canBecomeKey: Bool {
          return true
      }
      override var canBecomeMain: Bool {
          return true
      }
  }
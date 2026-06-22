//
//  BrowserManager.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/26.
//

import AppKit
import Foundation

@MainActor
final class BrowserManager {
    // MARK: - Singleton
    
    static let shared = BrowserManager()
    
    // MARK: - Initializer

    private init() {}

    // MARK: - Public Functions

    /// Parses `string` and returns the URL only when its scheme is `http` or `https`.
    ///
    /// `NSWorkspace.shared.open` dispatches by scheme via Launch Services and will happily invoke `file://`, `x-apple.systempreferences:`, arbitrary registered custom schemes, etc.
    /// This function prevents that.
    ///
    /// Whitespace is trimmed before parsing so copy-pasted URLs with stray leading/trailing spaces still resolve.
    static func getSafeWebURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return url
    }

    func findDefaultBrowserBundleURL() -> URL? {
        guard let probeURL = URL(string: "https://example.com") else { return nil }
        return NSWorkspace.shared.urlForApplication(toOpen: probeURL)
    }
    
    func openNewBrowserWindow(urls: [String] = []) async {
        guard let browserURL = findDefaultBrowserBundleURL()
        else {
            print("[BrowserManager]: No default browser registered with Launch Services.")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        let runningBrowser: NSRunningApplication
        
        /// Activating the browser app (making it front-most).
        do {
            runningBrowser = try await NSWorkspace.shared.openApplication(
                at: browserURL,
                configuration: config
            )
        } catch {
            print("[BrowserManager]: Failed to activate default browser: \(error.localizedDescription)")
            return
        }

        let didActivate = await waitUntilApplicationIsActive(matching: runningBrowser)

        if didActivate {
            openNewBrowserWindowWithCmdN(browserPid: runningBrowser.processIdentifier)
        } else {
            print("[BrowserManager]: Browser activation timed out — skipping new-window keystroke.")
        }

        /// Give the browser a beat to render the new window before we start firing URLs at it.
        try? await Task.sleep(for: .milliseconds(300))

        for urlString in urls {
            if let url = Self.getSafeWebURL(from: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Private Functions

    /// Returns `true` if the matching `runningApp` (the browser app) became front-most before `timeout` elapses (2s).
    /// Returns `false` otherwise.
    private func waitUntilApplicationIsActive(
        matching runningApp: NSRunningApplication,
        timeout: Duration = .seconds(2)
    ) async -> Bool {
        /// **Fast Path**
        ///     Browser is already frontmost so nothing to wait for. Return early.
        if runningApp.isActive {
            return true
        }

        return await withTaskGroup(of: Bool.self) { group in
            /// **Activation Observer**
            ///     Returns `true` as soon as the target app fires `NSWorkspace.didActivateApplicationNotification` (activates).
            group.addTask {
                for await notification in NSWorkspace.shared.notificationCenter.notifications(
                    named: NSWorkspace.didActivateApplicationNotification
                ) {
                    let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                    if activatedApp?.processIdentifier == runningApp.processIdentifier {
                        return true
                    }
                }
                return false
            }

            /// **Timeout Safety Net**
            ///     If the browser app window's activation never arrives, return `false` so the caller can skip downstream actions that assume the browser is frontmost.
            ///         For example, firing `openNewBrowserWindowWithCmdN()` should only happen when the browser becomes active before the `timeout`.
            group.addTask {
                try? await Task.sleep(for: timeout)
                return false
            }

            /// Whichever child task finishes first wins; cancel the other so the observer doesn't outlive its usefulness.
            let didActivate = await group.next() ?? false
            group.cancelAll()
            return didActivate
        }
    }

    /// Simulates a `cmd+n` keyboard shortcut at the HID event layer to open a new browser window.
    private func openNewBrowserWindowWithCmdN(browserPid: pid_t) {
        /// Checking that the current front-most app is the browser so that the `cmd+n` HID event properly targets it.
        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication,
              frontmostApplication.processIdentifier == browserPid
        else {
            print("[BrowserManager]: Target browser is no longer frontmost — skipping opening new browser window.")
            return
        }

        guard AccessibilityPermissionManager.shared.accessibilityPermissionStatus == .granted
        else {
            AnalyticsManager.Browser.requestOpenBrowserUrlWithoutAccessibilityPermission()
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: false)
        else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

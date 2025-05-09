//
//  AccessibilityObserversManager.swift
//  Onit
//
//  Created by Kévin Naudin on 08/05/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

@MainActor
class AccessibilityObserversManager {
    
    // MARK: - Properties
    
    weak var delegate: AccessibilityObserversDelegate?
    
#if DEBUG
    private let ignoredAppNames : [String] = ["Xcode"]
#else
    private let ignoredAppNames : [String] = []
#endif
    
    private var observers: [pid_t: AXObserver] = [:]
    private var persistentObservers: [pid_t: AXObserver] = [:]
    
    // Protection contre les appels rapides multiples
    private var lastStartTime: Date?
    private let minimumStartInterval: TimeInterval = 0.5 // 500ms
    
    enum ProcessAuthorizationState {
        case authorized
        case ignored
        case current
    }
    
    // MARK: - Functions
    
    func start(pid: pid_t?) {
        // Ensure we don't start twice too quickly
        if let lastStartTime = lastStartTime,
           Date().timeIntervalSince(lastStartTime) < minimumStartInterval {
            log.error("Ignoring rapid consecutive start call")
            return
        }
        
        lastStartTime = Date()
        
        stop()
        
        startAppActivationObservers()
        
        guard let pid = pid, authorizationState(for: pid) == .authorized else { return }
        
        let appName = pid.getAppName() ?? "Unknown"
        log.info("Observers automatically started for `\(appName)` (\(pid))")
        delegate?.accessibilityObserversManager(didActivateApplication: pid.getAppName(), processID: pid)
        startNotificationsObserver(for: pid)
        startPersistentNotificationsObserver(for: pid)
    }
    
    func stop() {
        stopAppActivationObservers()
        
        for pid in observers.keys {
            stopNotificationsObserver(for: pid)
        }
        
        for pid in persistentObservers.keys {
            stopPersistentNotificationsObserver(for: pid)
        }
    }
    
    private func startAppActivationObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivationReceived),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDeactivationReceived),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil)
    }
    
    private func stopAppActivationObservers() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc private func appActivationReceived(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else {
            log.error("Cannot subscribe to notifications - no NSRunningApplication found")
            return
        }
        
        switch authorizationState(for: app.processIdentifier) {
        case .current:
            log.debug("Ignoring activation of Onit (\(app.processIdentifier))")
        case .ignored:
            log.debug("Ignoring activation of `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier))")
            delegate?.accessibilityObserversManager(didActivateIgnoredApplication: app.localizedName)
        case .authorized:
            log.info("Application `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier)) activated")
            
            if !isAXServerInitialized(pid: app.processIdentifier) {
                log.error("AXServer not fully initialized")
                AccessibilityAnalytics.logAXServerInitializationError(app: app)
            }
            
            delegate?.accessibilityObserversManager(
                didActivateApplication: app.localizedName,
                processID: app.processIdentifier
            )
            
            startNotificationsObserver(for: app.processIdentifier)
            startPersistentNotificationsObserver(for: app.processIdentifier)
        }
    }
    
    @objc private func appDeactivationReceived(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else {
            log.error("Cannot unsubscribe to notifications - no NSRunningApplication found")
            return
        }
        
        // Check if Onit is activated so we don't deactivate the active app
        if let activeApp = NSWorkspace.shared.frontmostApplication,
           authorizationState(for: activeApp.processIdentifier) == .current {
            log.debug("Onit is active, ignoring deactivation of `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier))")
            return
        }
        
        switch authorizationState(for: app.processIdentifier) {
        case .current:
            log.info("Ignoring deactivation of Onit (\(app.processIdentifier))")
        case .ignored:
            log.info("Ignoring deactivation of `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier))")
        case .authorized:
            log.info("Application `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier)) deactivated")
            delegate?.accessibilityObserversManager(
                didDeactivateApplication: app.localizedName,
                processID: app.processIdentifier
            )
            stopNotificationsObserver(for: app.processIdentifier)
        }
    }
    
    private func startNotificationsObserver(for pid: pid_t) {
        stopNotificationsObserver(for: pid)
        
        let appName = pid.getAppName() ?? "Unknown"
        log.info("Registering observers for `\(appName)` (\(pid))")
        
        var observer: AXObserver?
        let observerCallback: AXObserverCallbackWithInfo = {
            observer, element, notification, userInfo, refcon in
            // Dispatch to main thread immediately
            log.info("Notification received: \(notification)")
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<AccessibilityObserversManager>
                    .fromOpaque(refcon!)
                    .takeUnretainedValue()
                let userInfo = userInfo as! [String: Any] as Dictionary
                
                accessibilityInstance.handleAccessibilityNotifications(
                    notification as String, element: element, info: userInfo)
            }
        }

        let result = AXObserverCreateWithInfoCallback(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observers[pid] = observer
            
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            
            var notifications = Config.notifications
            
            if HighlightedTextCoordinator.appNames.contains(pid.getAppName() ?? "") {
                notifications.removeAll(where: { $0 == kAXSelectedTextChangedNotification })
            }
            
            for notification in notifications {
                AXObserverAddNotification(
                    observer,
                    pid.getAXUIElement(),
                    notification as CFString,
                    refCon
                )
            }
            
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            
            log.info("Observer registered for `\(appName)` (\(pid))")
        } else {
            log.error("Failed to register observer for `\(appName)` (\(pid))")
            AccessibilityAnalytics.logObserverError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }
    
    private func startPersistentNotificationsObserver(for pid: pid_t) {
        let appName = pid.getAppName() ?? "Unknown"
        guard persistentObservers[pid] == nil else {
            log.debug("Persistent observer already registered for `\(appName)` (\(pid))")
            return
        }
        
        log.info("Registering persistent observers for `\(appName)` (\(pid))")
        
        var observer: AXObserver?
        let observerCallback: AXObserverCallbackWithInfo = {
            observer, element, notification, userInfo, refcon in
            // Dispatch to main thread immediately
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<AccessibilityObserversManager>
                    .fromOpaque(refcon!)
                    .takeUnretainedValue()
                let userInfo = userInfo as! [String: Any] as Dictionary
                
                accessibilityInstance.handlePersistentAccessibilityNotifications(
                    notification as String, element: element, info: userInfo)
            }
        }

        let result = AXObserverCreateWithInfoCallback(pid, observerCallback, &observer)
        
        if result == .success, let observer = observer {
            self.persistentObservers[pid] = observer
            
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            
            for notification in Config.persistentNotifications {
                AXObserverAddNotification(
                    observer,
                    pid.getAXUIElement(),
                    notification as CFString,
                    refCon
                )
            }
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            
            log.info("Persistent observer registered for `\(appName)` (\(pid))")
        } else {
            log.error("Failed to register persistent observer for `\(appName)` (\(pid))")
            AccessibilityAnalytics.logObserverError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }
    
    private func stopNotificationsObserver(for pid: pid_t) {
        guard let existingObserver = self.observers[pid] else { return }

        let runLoopSource = AXObserverGetRunLoopSource(existingObserver)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        for notification in Config.notifications {
            AXObserverRemoveNotification(
                existingObserver,
                pid.getAXUIElement(),
                notification as CFString
            )
        }

        observers.removeValue(forKey: pid)
        log.info("Stopped observing notifications for `\(pid.getAppName() ?? "Unknown")` (\(pid))")
    }
    
    private func stopPersistentNotificationsObserver(for pid: pid_t) {
        guard let existingObserver = self.persistentObservers[pid] else { return }
        
        let runLoopSource = AXObserverGetRunLoopSource(existingObserver)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            
        for notification in Config.persistentNotifications {
            AXObserverRemoveNotification(
                existingObserver,
                pid.getAXUIElement(),
                notification as CFString
            )
        }
        
        persistentObservers.removeValue(forKey: pid)
        log.info("Stopped observing persistent notifications for `\(pid.getAppName() ?? "Unknown")` (\(pid))")
    }
    
    // MARK: - Notifications handling
    
    private func handleAccessibilityNotifications(
        _ notification: String, element: AXUIElement, info: [String: Any]
    ) {
        log.info("Notification received: \(notification)")
        if let elementPid = element.pid() {
           delegate?.accessibilityObserversManager(
                didReceiveNotification: notification,
                element: element,
                elementPid: elementPid,
                info: info
            )
        }
    }
    
    private func handlePersistentAccessibilityNotifications(
        _ notification: String, element: AXUIElement, info: [String: Any]
    ) {
        log.info("Persistent notification received: \(notification)")
        if let elementPid = element.pid() {
            delegate?.accessibilityObserversManager(
                didReceiveNotification: notification,
                element: element,
                elementPid: elementPid,
                info: info
            )
        }
    }
    
    private func authorizationState(for pid: pid_t) -> ProcessAuthorizationState {
        let appName = pid.getAppName()
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        if pid == getpid() || appName == onitName {
            return .current
        } else if ignoredAppNames.contains(appName ?? "") {
            return .ignored
        }
        
        return .authorized
    }
    
    private func isAXServerInitialized(pid: pid_t) -> Bool {
        func isAppleApplication(for pid: pid_t) -> Bool {
            guard let bundleIdentifier = pid.bundleIdentifier else {
                return false
            }
            
            return bundleIdentifier.starts(with: "com.apple.")
        }
        
        func canReadFocusedUIElement(for pid: pid_t) -> Bool {
            let appElement = pid.getAXUIElement()
            
            var focusedElement: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            if result == .success {
                return true
            } else {
                if result == .cannotComplete {
                    log.error("We're stuck with Accessibility")
                }
                return false
            }
        }
        
        guard !isAppleApplication(for: pid) else {
            return true
        }
        
        return canReadFocusedUIElement(for: pid)
    }
}

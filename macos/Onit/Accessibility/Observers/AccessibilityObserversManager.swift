//
//  AccessibilityObserversManager.swift
//  Onit
//
//  Created by Kévin Naudin on 08/05/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

/// Enum to determine how a process should be handled for accessibility observations
enum ProcessObservationEligibility {
    case eligible
    case ignoreProcess
    case ownProcess
}

@MainActor
class AccessibilityObserversManager {
    
    // MARK: - Singleton
    
    static let shared = AccessibilityObserversManager()
    
    // MARK: - Properties
    
    weak var delegate: AccessibilityObserversDelegate?
    
    private lazy var ignoredAppNames: [String] = Self.currentIgnoredAppNames
    
    private var observers: [pid_t: AXObserver] = [:]
    private var persistentObservers: [pid_t: AXObserver] = [:]
    
    private var isStarted = false
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func start() {
        guard !isStarted else { return }
        
        isStarted = true
        
        startAppActivationObservers()
        
        // Always start observing our own process for typeahead learning
        // This ensures TypingChangeDelegate can capture typing in Onit's interface
        // Uses minimal notification set to reduce processing overhead
        startOwnProcessObserver()
    }
    
    func stop() {
        isStarted = false
        
        stopAppActivationObservers()
        
        for pid in observers.keys {
            stopNotificationsObserver(for: pid)
        }
        
        for pid in persistentObservers.keys {
            stopPersistentNotificationsObserver(for: pid)
        }
        
        // Clean up our own process observer
        stopOwnProcessObserver()
    }
    
    /**
     * Called once at app launch if accessibility permission is granted.
     * Needed to start monitoring the foreground app manually since
     * app activation notifications aren’t delivered at launch.
     */
    func startAccessibilityObserversOnFirstLaunch(with pid: pid_t) {
        let appName = pid.appName ?? "Unknown"
        log.info("Observers automatically started for `\(appName)` (\(pid))")
        
        let authState = authorizationState(for: pid)
        let hasAnyDelegateWantingAllProcesses = (delegate as? AccessibilityNotificationsManager)?.hasAnyDelegateWantingAllProcesses() ?? false
        
        switch authState {
        case .ownProcess:
            delegate?.accessibilityObserversManager(didActivateOnit: pid.appName, processID: pid)
            // Note: Own process observer is already running from startup - no need to start again
        case .ignoreProcess:
            delegate?.accessibilityObserversManager(didActivateIgnoredApplication: pid.appName, processID: pid)
            if hasAnyDelegateWantingAllProcesses {
                // Start full notification set for delegates that want all processes
                startNotificationsObserver(for: pid, notifications: Config.notifications)
                startPersistentNotificationsObserver(for: pid)
            } else {
                startNotificationsObserver(for: pid, notifications: Config.untrackedAppNotifications)
            }
        case .eligible:
            delegate?.accessibilityObserversManager(didActivateApplication: pid.appName, processID: pid)
            startNotificationsObserver(for: pid, notifications: Config.notifications)
            startPersistentNotificationsObserver(for: pid)
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
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Starts observing our own process for typeahead learning
    /// Only subscribes to minimal notification set to reduce processing overhead
    private func startOwnProcessObserver() {
        let currentPid = getpid()
        let appName = currentPid.appName ?? "Onit"
        
        // Start notifications with minimal set for our own process
        startNotificationsObserver(for: currentPid, notifications: Config.onitNotifications)    
    }
    
    /// Stops observing our own process
    private func stopOwnProcessObserver() {
        let currentPid = getpid()
        stopNotificationsObserver(for: currentPid)
        log.info("Stopped own process observer for `\(currentPid.appName ?? "Onit")` (\(currentPid))")
    }

    @objc private func appActivationReceived(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else {
            log.error("Cannot subscribe to notifications - no NSRunningApplication found")
            return
        }
        let appName = app.processIdentifier.appName
        print("appActivationReceived for appName: \(appName)")
        
        let authState = authorizationState(for: app.processIdentifier)
        let hasAnyDelegateWantingAllProcesses = (delegate as? AccessibilityNotificationsManager)?.hasAnyDelegateWantingAllProcesses() ?? false
        
        
        switch authState {
        case .ownProcess:
            log.debug("Onit activated (\(app.processIdentifier))")
            delegate?.accessibilityObserversManager(
                didActivateOnit: app.localizedName,
                processID: app.processIdentifier
            )
            // Note: Own process observer is already running from startup - no need to start again
        case .ignoreProcess:
            log.debug("Ignored application `\(app.localizedName ?? "Unknown")` activated (\(app.processIdentifier))")
            delegate?.accessibilityObserversManager(
                didActivateIgnoredApplication: app.localizedName,
                processID: app.processIdentifier
            )
            if hasAnyDelegateWantingAllProcesses {
                // Start full notification set for delegates that want all processes
                startNotificationsObserver(for: app.processIdentifier, notifications: Config.notifications)
                startPersistentNotificationsObserver(for: app.processIdentifier)
            }
        case .eligible:
            log.info("Application `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier)) activated")
            
            if !isAXServerInitialized(pid: app.processIdentifier) {
                log.error("AXServer not fully initialized")
                AnalyticsManager.Accessibility.serverInitializationError(app: app)
            }
            
            delegate?.accessibilityObserversManager(
                didActivateApplication: app.localizedName,
                processID: app.processIdentifier
            )
            
            startNotificationsObserver(for: app.processIdentifier, notifications: Config.notifications)
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
//        if let activeApp = NSWorkspace.shared.frontmostApplication,
//           authorizationState(for: activeApp.processIdentifier) == .ownProcess {
//            log.debug("Onit is active, ignoring deactivation of `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier))")
//            return
//        }//
        let hasAnyDelegateWantingAllProcesses = (delegate as? AccessibilityNotificationsManager)?.hasAnyDelegateWantingAllProcesses() ?? false
        
        switch authorizationState(for: app.processIdentifier) {
        case .ownProcess:
            // Do nothing, Onit deactivation is not handled
            break
        case .ignoreProcess:
            log.debug("Ignored application `\(app.localizedName ?? "Unknown")` deactivated (\(app.processIdentifier))")
            delegate?.accessibilityObserversManager(
                didDeactivateApplication: app.localizedName,
                processID: app.processIdentifier
            )
            if hasAnyDelegateWantingAllProcesses {
                stopNotificationsObserver(for: app.processIdentifier)
            }
        case .eligible:
            log.info("Application `\(app.localizedName ?? "Unknown")` (\(app.processIdentifier)) deactivated")
            delegate?.accessibilityObserversManager(
                didDeactivateApplication: app.localizedName,
                processID: app.processIdentifier
            )
            stopNotificationsObserver(for: app.processIdentifier)
        }
    }
    
    private func startNotificationsObserver(for pid: pid_t, notifications: [String]) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.startNotificationsObserver(for: pid, notifications: notifications)
            }
            return
        }
        stopNotificationsObserver(for: pid)
        
        let appName = pid.appName ?? "Unknown"
        log.info("Registering observers for `\(appName)` (\(pid))")
        
        var observer: AXObserver?
        let observerCallback: AXObserverCallbackWithInfo = {
            observer, element, notification, userInfo, refcon in
            // Dispatch to main thread immediately
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<AccessibilityObserversManager>
                    .fromOpaque(refcon!)
                    .takeUnretainedValue()
                let userInfo: [String: Any] = (userInfo as? [String: Any]) ?? [:]
                
                accessibilityInstance.handleAccessibilityNotifications(
                    notification as String, element: element, info: userInfo)
            }
        }

        let result = AXObserverCreateWithInfoCallback(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observers[pid] = observer
            
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            
            var notifications = notifications
            if HighlightedTextCoordinator.appNames.contains(pid.appName ?? "") {
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
            
            log.info("ObserveDebug: Observer registered for `\(appName)` (\(pid))")
        } else {
            log.error("Failed to register observer for `\(appName)` (\(pid))")
            AnalyticsManager.Accessibility.observerError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }
    
    private func startPersistentNotificationsObserver(for pid: pid_t) {
        let appName = pid.appName ?? "Unknown"
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
                let userInfo: [String: Any] = (userInfo as? [String: Any]) ?? [:]
                
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
            AnalyticsManager.Accessibility.observerError(
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
        log.info("ObserveDebug: Stopped observing notifications for `\(pid.appName ?? "Unknown")` (\(pid))")
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
        log.info("Stopped observing persistent notifications for `\(pid.appName ?? "Unknown")` (\(pid))")
    }
    
    // MARK: - Notifications handling
    
    private func handleAccessibilityNotifications(
        _ notification: String, element: AXUIElement, info: [String: Any]
    ) {
        // log.info("Notification received: \(notification)")
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
        // log.info("Persistent notification received: \(notification)")
        if let elementPid = element.pid() {
            delegate?.accessibilityObserversManager(
                didReceiveNotification: notification,
                element: element,
                elementPid: elementPid,
                info: info
            )
        }
    }
    
    private func authorizationState(for pid: pid_t) -> ProcessObservationEligibility {
        return Self.determineProcessObservationEligibility(for: pid, ignoredAppNames: ignoredAppNames)
    }
    
    /// Static method to determine process observation eligibility that can be used by other managers
    static func determineProcessObservationEligibility(for pid: pid_t, ignoredAppNames: [String]) -> ProcessObservationEligibility {
        let appName = pid.appName
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        if pid == getpid() || appName == onitName {
            return .ownProcess
        } else if ignoredAppNames.contains(appName ?? "") {
            return .ignoreProcess
        }
        
        return .eligible
    }
    
    /// Static method to get the current ignored app names (for consistency across managers)
    static var currentIgnoredAppNames: [String] {
#if DEBUG
        return ["Xcode"]
#else
        return []
#endif
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
                return false
            }
        }
        
        guard !isAppleApplication(for: pid) else {
            return true
        }
        
        return canReadFocusedUIElement(for: pid)
    }
}

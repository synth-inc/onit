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
    
    private var skipNextDeactivation = false
    
    // MARK: - Functions
    
    func start(pid: pid_t?) {
        stop()
        
        startAppActivationObservers()
        
        guard let pid = pid, isProcessAllowed(appPid: pid) else { return }
        
        print("Observers started with \(pid.getAppName()) process identifier")
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
            stopPersistentNotificationsObservers(for: pid)
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
        
        guard isProcessAllowed(appPid: app.processIdentifier, ignoredCallback: { appName in
            log.debug("Ignoring activation of `\(appName ?? "")`")
            self.delegate?.accessibilityObserversManager(didActivateIgnoredApplication: app.localizedName)
        }) else {
            log.debug("Application not allowed to be monitored: \(app.localizedName ?? "Unknown")")
//            skipNextDeactivation = true
            return
        }
        
        log.info("Application `\(app.localizedName ?? "")` activated with pid: \(app.processIdentifier)")
        
        delegate?.accessibilityObserversManager(
            didActivateApplication: app.localizedName,
            processID: app.processIdentifier
        )
        
        startNotificationsObserver(for: app.processIdentifier)
        startPersistentNotificationsObserver(for: app.processIdentifier)
    }
    
    @objc private func appDeactivationReceived(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else {
            log.error("Cannot unsubscribe to notifications - no NSRunningApplication found")
            return
        }
        
        guard isProcessAllowed(appPid: app.processIdentifier) else {
            log.debug("Application not allowed to be monitored: \(app.localizedName ?? "Unknown")")
            return
        }
        
//        guard !skipNextDeactivation else {
//            skipNextDeactivation = false
//            return
//        }
        
        log.info("Application `\(app.localizedName ?? "")` deactivated with pid: \(app.processIdentifier)")
        
        delegate?.accessibilityObserversManager(
            didDeactivateApplication: app.localizedName,
            processID: app.processIdentifier
        )
        stopNotificationsObserver(for: app.processIdentifier)
    }
    
    private func startNotificationsObserver(for pid: pid_t) {
        stopNotificationsObserver(for: pid)
        
        let appName = pid.getAppName()
        log.info("Registering observers for \(appName ?? "Unknown") with PID: \(pid)")
        
        var observer: AXObserver?
        let observerCallback: AXObserverCallbackWithInfo = {
            observer, element, notification, userInfo, refcon in
            // Dispatch to main thread immediately
            log.info("notification received \(notification)")
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
            
            log.info("Observer registered for \(appName ?? "Unknown") with PID: \(pid)")
        } else {
            log.error("Failed to registering observer for \(appName ?? "Unknown") with PID: \(pid)")
            AccessibilityAnalytics.logObserverError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }
    
    private func startPersistentNotificationsObserver(for pid: pid_t) {
        let appName = pid.getAppName() ?? "Unknown"
        guard persistentObservers[pid] == nil else {
            log.debug("Persistent observer already registered for app: \(appName)")
            return
        }
        
        log.info("Registering persistent observers for \(appName) with PID: \(pid)")
        
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
            
            log.info("Persistent observer registered for \(appName) with PID: \(pid)")
        } else {
            log.error("Failed to registering observer for \(appName) with PID: \(pid)")
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
        log.info("Stop observing notifications for PID: \(pid).")
    }
    
    private func stopPersistentNotificationsObservers(for pid: pid_t) {
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
        log.info("Stop observing persistent notifications for PID: \(pid).")
    }
    
    // MARK: - Notifications handling
    
    private func handleAccessibilityNotifications(
        _ notification: String, element: AXUIElement, info: [String: Any]
    ) {
        log.info("notification: \(notification)")
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
        log.info("notification: \(notification)")
        if let elementPid = element.pid() {
            delegate?.accessibilityObserversManager(
                didReceiveNotification: notification,
                element: element,
                elementPid: elementPid,
                info: info
            )
        }
    }
    
    private func isProcessAllowed(appPid: pid_t, ignoredCallback: ((String?) -> Void)? = nil) -> Bool {
        let appName = appPid.getAppName()
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        if appPid == getpid() || appName == onitName {
            return false
        } else if ignoredAppNames.contains(appName ?? "") {
            ignoredCallback?(appName)
            
            return false
        }
        
        return true
    }
}

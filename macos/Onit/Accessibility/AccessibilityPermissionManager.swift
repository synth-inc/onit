//
//  AccessibilityPermissionManager.swift
//  Onit
//
//  Created by Kévin Naudin on 16/01/2025.
//

@preconcurrency import ApplicationServices.HIServices.AXUIElement

/**
 * Helper for requesting Accessibility's Permission
 *
 * The `@preconcurrency` annotation is used because of `kAXTrustedCheckOptionPrompt` usage.
 */
@MainActor
class AccessibilityPermissionManager {
    
    // MARK: Singleton instance
    
    static let shared = AccessibilityPermissionManager()
    
    // MARK: Properties
    
    /** Get the actual state of permission. True means trusted, otherwise it's false */
    static var isProcessTrusted: Bool { AXIsProcessTrusted() }
    
    /** Optional timer to launch if permission is not trusted */
    private var processTrustedTimer: Timer?
    
    /** Get the state of permission managed by the `Timer` */
    private var isProcessTrustedFromTimer: Bool?
    
    /** Optional closure to execute when permission untrusted */
    private var onProcessUntrusted: (() -> Void)?
    
    /** Optional closure to execute when permission trusted */
    private var onProcessTrusted: (() -> Void)?
    
    // MARK: Functions
    
    /**
     * Requests accessibility permissions if they are not already granted.
     *
     * This function monitors whether the application has the required accessibility permissions,
     * accessible through **System Preferences > Security & Privacy > Accessibility**.
     *
     * If the permissions are granted, the `onTrusted` closure is called.
     * If the permissions are not granted,  the `onUntrusted` closure is called.
     *
     * - parameter onUntrusted: optional closure to execute when permission untrusted
     * - parameter onTrusted: optional closure to execute when permission trusted
     */
    func requestPermission(onUntrusted: (() -> Void)?, onTrusted: (() -> Void)?) {
        onProcessUntrusted = onUntrusted
        onProcessTrusted = onTrusted
        
        processTrustedTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                   target: self,
                                                   selector: #selector(checkProcessTrusted),
                                                   userInfo: nil,
                                                   repeats: true)
        
        guard !AccessibilityPermissionManager.isProcessTrusted else { return }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: Obj-c Functions
    
    /** Timer callback method */
    @objc private func checkProcessTrusted() {
        let isProcessTrusted = AccessibilityPermissionManager.isProcessTrusted
        
        if isProcessTrustedFromTimer != isProcessTrusted {
            isProcessTrustedFromTimer = isProcessTrusted
            
            if isProcessTrusted {
                onProcessTrusted?()
            } else {
                onProcessUntrusted?()
            }
        }
    }
}

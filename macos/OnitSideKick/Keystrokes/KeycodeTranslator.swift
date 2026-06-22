//
//  KeycodeTranslator.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/25/25.
//

import AppKit
import CoreText
import Foundation
//import UIKit

// Job structure to hold event and callback
private struct KeyEventJob {
    let event: NSEvent
    let callback: (String?, Bool) -> Void
    let completion: (String?, Bool) -> Void
}

// Lookup table mapping special key keyCodes to human-readable names
private let specialKeyLookup: [UInt16: String] = [
    // Arrow keys
    123: "left",
    124: "right",
    125: "down",
    126: "up",

    // Function keys (F1-F20)
    122: "f1",
    120: "f2",
    99:  "f3",
    118: "f4",
    96:  "f5",
    97:  "f6",
    98:  "f7",
    100: "f8",
    101: "f9",
    109: "f10",
    103: "f11",
    111: "f12",
    105: "f13",
    107: "f14",
    113: "f15",
    106: "f16",
    64:  "f17",
    79:  "f18",
    80:  "f19",
    90:  "f20",

    // Keys above arrow keys
    115: "home",
    119: "end",
    116: "pageup",
    121: "pagedown",
    114: "help",
    117: "forward_delete",

    // Other special keys
    53:  "escape",
    51:  "delete",
    36:  "return",
    48:  "tab",
    76:  "enter", // Keypad enter

    // Miscellaneous
    72:  "volume_up",
    73:  "volume_down",
    74:  "mute",
    39:  "caps_lock",
    63:  "fn"
]


final class KeycodeTranslator: NSResponder, Sendable {
    static let shared = KeycodeTranslator()
    
    // MARK: - Thread-Safe State Access
    // Variables are separated by the queue on which they must be accessed to ensure thread safety.
    // All access to these variables must happen on their respective queues.
    
    // Variables accessed on processingQueue (serial queue for job processing state)
    // These must be accessed/modified only while on processingQueue to prevent race conditions.
    private var jobQueue: [KeyEventJob] = []
    private var isProcessing = false
    private var isResetting = false  // Prevents concurrent resets
    private var lastJobStartTime: Date?  // Watchdog state tracking
    
    // Variables accessed on mainQueue (for UI/responder chain operations)
    // These must be accessed/modified only on the main thread (NSWindow and NSResponder requirements).
    private var dedicatedWindow: NSWindow?  // Dedicated window for responder chain isolation
    private var currentJob: KeyEventJob?  // Current job being processed (set/cleared on main thread)
    
    // Constants and queue configuration
    private let processingQueue = DispatchQueue(label: "com.onit.keycode-translator", qos: .userInteractive)
    private let maxQueueSize = 10
    private let maxJobDuration: TimeInterval = 5.0
    
    public static let textProducingCommands: Set<String> = [
        "tab",
        "return",
        "enter",
        "cmd+v",
        "cmd+z",
        "cmd+shift+z",
        "cmd+k"
    ]
    
    private override init() {
        super.init()
        setupDedicatedWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDedicatedWindow() {
       // Check if we already have a dedicated window
       if dedicatedWindow != nil {
           return
       }
       
       // Create a dedicated hidden window for responder chain isolation
       dedicatedWindow = NSWindow(
           contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
           styleMask: [.borderless],
           backing: .buffered,
           defer: false
       )
       
       // Configure the window to be invisible and off-screen
       dedicatedWindow?.isOpaque = false
       dedicatedWindow?.backgroundColor = NSColor.clear
       dedicatedWindow?.level = .normal
       dedicatedWindow?.ignoresMouseEvents = true
       dedicatedWindow?.isReleasedWhenClosed = false
       dedicatedWindow?.orderOut(nil)
       
       // Set up the responder chain with the dedicated window
       dedicatedWindow?.nextResponder = self
       
       #if DEBUG
       print("keycodeTranslator: setupDedicatedWindow: Dedicated window created and responder chain established")
       #endif
   }
   
   private func ensureInResponderChain() {
        // If dedicated window doesn't exist, create it
        if dedicatedWindow == nil {
            setupDedicatedWindow()
        }
   }

    /// Returns the character for the given NSEvent, considering current modifiers, via a callback.
    /// The callback receives the character string and a boolean indicating if it was an insertText (true) or doCommand (false) callback.
    func characterForEvent(_ event: NSEvent, callback: @escaping (String?, Bool) -> Void) {
        // FlagsChanged events (modifier keys only) cannot be processed by interpretKeyEvents
        guard event.type != .flagsChanged else {
            callback(nil, false)
            return
        }

        let job = KeyEventJob(
            event: event,
            callback: callback,
            completion: { [weak self] result, isInsertText in
                // Execute callback on main queue since it might update UI
                DispatchQueue.main.async {
                    callback(result, isInsertText)
                }
                // Continue processing next job
                self?.processNextJob()
            }
        )
        
        // All state mutations must happen on processingQueue
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check watchdog conditions before adding new job
            self.checkWatchdogConditions()
            
            self.jobQueue.append(job)
            #if DEBUG
            print("KeycodeTranslator: added job, queue length \(jobQueue.count)")
            #endif
            // Start processing if not already running
            if !self.isProcessing {
                self.processNextJob()
            }
        }
    }
    
    
    private func processNextJob() {
        // Dispatch to processingQueue to ensure thread-safe state access
        processingQueue.async { [weak self] in
            self?.processNextJobSync()
        }
    }
    
    private func processNextJobSync() {
        // This method must be called on processingQueue
        guard !jobQueue.isEmpty else {
            isProcessing = false
            lastJobStartTime = nil
            return
        }
        isProcessing = true
        let job = jobQueue.removeFirst()
        
        // Track when this job started for watchdog monitoring
        lastJobStartTime = Date()
        
        // Switch to main queue for interpretKeyEvents since it needs UI context
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ensureInResponderChain()
            self.currentJob = job
            self.interpretKeyEvents([job.event])
        }
    }
    
    // MARK: Watchdog Monitoring
    
    private func checkWatchdogConditions() {
        // This method must be called on processingQueue
        // Prevent concurrent resets
        if isResetting {
            return
        }
        
        var shouldReset = false
        
        // Check if queue has grown too large
        if jobQueue.count >= maxQueueSize {
            shouldReset = true
            #if DEBUG
            print("KeycodeTranslator: Watchdog triggered - queue size (\(jobQueue.count)) >= max (\(maxQueueSize))")
            #endif
        }
        
        // Check if current job has been processing too long
        if let startTime = lastJobStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > maxJobDuration {
                shouldReset = true
                #if DEBUG
                print("KeycodeTranslator: Watchdog triggered - job duration (\(elapsed)s) > max (\(maxJobDuration)s)")
                #endif
            }
        }
        
        if shouldReset {
            resetTranslator()
        }
    }
    
    private func resetTranslator() {
        // This method must be called on processingQueue
        // Set flag and clear state immediately to prevent concurrent resets
        guard !isResetting else {
            #if DEBUG
            print("KeycodeTranslator: Reset already in progress, skipping")
            #endif
            return
        }
        
        isResetting = true
        
        // Drain the job queue - discard all stale jobs that no longer need to be processed
        let discardedJobsCount = jobQueue.count
        #if DEBUG
        if discardedJobsCount > 0 {
            print("KeycodeTranslator: Resetting translator - discarding \(discardedJobsCount) stale job(s) from queue")
        }
        #endif
        jobQueue.removeAll()
        
        // Clear state immediately on processingQueue to prevent new jobs from triggering another reset
        lastJobStartTime = nil
        isProcessing = false
        
        // Now dispatch to main thread for window operations
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Read currentJob on main thread (where it's accessed)
            let stuckJob = self.currentJob
            
            // Log stuck job details before clearing
            if let job = stuckJob {
                self.logJobDetails(job: job)
            } else {
                #if DEBUG
                print("KeycodeTranslator: Resetting translator - clearing stuck state (no current job)")
                #endif
            }
            
            // Clear currentJob on main thread
            self.currentJob = nil
            
            // Close existing window
            if let window = self.dedicatedWindow {
                window.close()
            }
            self.dedicatedWindow = nil
            
            // Recreate the window
            self.setupDedicatedWindow()
            
            // Try to make the window first responder
            if let window = self.dedicatedWindow {
                window.makeKey()
            }

            // Reset complete - clear flag on processingQueue
            // Note: jobQueue is already empty (drained during reset), so no need to process next job
            self.processingQueue.async { [weak self] in
                guard let self = self else { return }
                self.isResetting = false
            }
        }
    }

    // MARK: NSResponder
    
    override func insertText(_ insertString: Any) {
        guard let job = currentJob else { return }
        #if DEBUG
        print("KeycodeTranslator: insertText: \(insertString)")
        #endif
        // Convert insertString to String
        let result: String?
        if let string = insertString as? String {
            result = string
        } else if let attributedString = insertString as? NSAttributedString {
            result = attributedString.string
        } else {
            result = String(describing: insertString)
        }
        // Clear currentJob on main thread (where it's accessed)
        currentJob = nil
        // Clear lastJobStartTime on processingQueue (where state is managed)
        processingQueue.async { [weak self] in
            self?.lastJobStartTime = nil
        }
        // Complete the job with isInsertText = true
        job.completion(result, true)
    }
    
    // Notes: tab, enter, and delete trigger 'doCommand'
    override func doCommand(by selector: Selector) {
        guard let job = currentJob else { return }
    
        // Concatenate any modifiers with the 'charactersIgnoringModifiers' field of the NSEvent.
        let event = job.event
        var keyNoModifiers = event.charactersIgnoringModifiers ?? ""
        
        // When there's no corresponding glyph, it generally means it's a special key.
        if !fontHasGlyph(for: keyNoModifiers.utf16) {
            let keyCode = event.keyCode
            let specialKey = specialKeyLookup[keyCode]
            if let specialKey = specialKey {
                keyNoModifiers = specialKey
            } else {
                let unicodeScalar = event.charactersIgnoringModifiers?.unicodeScalars.first
                if let unicodeScalar = unicodeScalar {
                    keyNoModifiers = "unknown(\(keyCode), U+\(String(format: "%04X", unicodeScalar.value)))"
                } else {
                    keyNoModifiers = "unknown(\(keyCode), noUnicodeScalar)"
                }
            }
        }
        
        var modifiers: [String] = []
        if event.modifierFlags.contains(.control) { modifiers.append("ctrl") }
        if event.modifierFlags.contains(.option) { modifiers.append("opt") }
        if event.modifierFlags.contains(.command) { modifiers.append("cmd") }
        if event.modifierFlags.contains(.shift) { modifiers.append("shift") }
        let result: String
        
            
        if modifiers.isEmpty {
            result = keyNoModifiers
        } else {
            result = modifiers.joined(separator: "+") + "+" + keyNoModifiers
        }        
        
        // Clear currentJob on main thread (where it's accessed)
        currentJob = nil
        // Clear lastJobStartTime on processingQueue (where state is managed)
        processingQueue.async { [weak self] in
            self?.lastJobStartTime = nil
        }
        // Complete the job with isInsertText = false
        job.completion(result, false)
    }
    
    func fontHasGlyph(for utf16: String.UTF16View) -> Bool {
        // Use NSFont on macOS instead of UIFont
        let nsFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let ctFont = CTFontCreateWithName(nsFont.fontName as CFString, nsFont.pointSize, nil)
        var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
        
        // Convert UTF16 code units to glyphs
        let foundGlyphs = CTFontGetGlyphsForCharacters(ctFont, Array(utf16), &glyphs, utf16.count)

        // Check if glyph(s) found and not 0 (0 indicates missing glyph)
        if foundGlyphs {
            for glyph in glyphs {
                if glyph == 0 {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
    
    private func logJobDetails(job: KeyEventJob) {
        let event = job.event
        let keyCode = event.keyCode
        let characters = event.characters ?? ""
        let charactersIgnoringModifiers = event.charactersIgnoringModifiers ?? ""
        var modifiers: [String] = []
        if event.modifierFlags.contains(.control) { modifiers.append("ctrl") }
        if event.modifierFlags.contains(.option) { modifiers.append("opt") }
        if event.modifierFlags.contains(.command) { modifiers.append("cmd") }
        if event.modifierFlags.contains(.shift) { modifiers.append("shift") }
        let modifierString = modifiers.isEmpty ? "none" : modifiers.joined(separator: "+")
        #if DEBUG
        print("KeycodeTranslator: Job details - keyCode: \(keyCode), characters: '\(characters)', charactersIgnoringModifiers: '\(charactersIgnoringModifiers)', modifiers: \(modifierString)")
        #endif
    }

    
    
    // MARK: Navigation classification
    /// Returns true if the given event/commandString represents a navigation action (caret move/submit), not text insertion.
    static func isNavigation(event: NSEvent, commandString: String?) -> Bool {
        let navKeyCodes: Set<UInt16> = [
            123, // left
            124, // right
            125, // down
            126, // up
            115, // home
            119, // end
            116, // pageUp
            121, // pageDown
            36,  // return
            76   // keypad enter
        ]
        if navKeyCodes.contains(event.keyCode) {
            return true
        }

        // Emacs-style navigation bindings (control + letter)
        if let cs = commandString?.lowercased() {
            let navCommands: Set<String> = [
                "ctrl+a", // line start
                "ctrl+e", // line end
                "ctrl+f", // char forward
                "ctrl+b", // char back
                "ctrl+p", // line up
                "ctrl+n"  // line down
            ]
            if navCommands.contains(cs) {
                return true
            }
        }

        return false
    }
}

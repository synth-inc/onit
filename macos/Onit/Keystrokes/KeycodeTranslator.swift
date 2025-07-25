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
    let callback: (String?) -> Void
    let completion: (String?) -> Void
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
    
    private var jobQueue: [KeyEventJob] = []
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.onit.keycode-translator", qos: .userInteractive)
    
    private override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Returns the character for the given NSEvent, considering current modifiers, via a callback.
    func characterForEvent(_ event: NSEvent, callback: @escaping (String?) -> Void) {
        let job = KeyEventJob(
            event: event,
            callback: callback,
            completion: { [weak self] result in
                // Execute callback on main queue since it might update UI
                DispatchQueue.main.async {
                    callback(result)
                }
                // Continue processing next job
                self?.processNextJob()
            }
        )
        
        jobQueue.append(job)
        
        // Start processing if not already running
        if !isProcessing {
            processNextJob()
        }
    }
    
    private func processNextJob() {
        guard !jobQueue.isEmpty else {
            isProcessing = false
            return
        }
        
        isProcessing = true
        let job = jobQueue.removeFirst()
        
        // Process on background queue to avoid blocking main queue
        processingQueue.async { [weak self] in
            // Switch back to main queue for interpretKeyEvents since it needs UI context
            DispatchQueue.main.async {
                self?.currentJob = job
                self?.interpretKeyEvents([job.event])
            }
        }
    }
    
    // Track current job being processed
    private var currentJob: KeyEventJob?

    // MARK: NSResponder
    
    override func insertText(_ insertString: Any) {
        guard let job = currentJob else { return }
        
        // Convert insertString to String
        let result: String?
        if let string = insertString as? String {
            result = string
        } else if let attributedString = insertString as? NSAttributedString {
            result = attributedString.string
        } else {
            result = String(describing: insertString)
        }
        // Complete the job
        job.completion(result)
        currentJob = nil
    }
    
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
        // Complete the job
        job.completion(result)
        currentJob = nil
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
}

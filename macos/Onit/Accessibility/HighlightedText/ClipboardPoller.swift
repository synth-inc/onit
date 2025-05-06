//
//  ClipboardPoller.swift
//  Onit
//
//  Created by Kévin Naudin on 06/05/2025.
//

import AppKit
import Carbon
import Foundation

class ClipboardPoller {
    
    // MARK: - Properties
    
    private let interval: TimeInterval = 0.3
    private let queue = DispatchQueue(label: "inc.synth.onit.ClipboardPoller", qos: .background)
    private let cKeyCode: CGKeyCode
    
    private var timer: DispatchSourceTimer?
    
    init() {
        var tempKeyCode: CGKeyCode = 8 // Default value ('c' on QWERTY)
        
        if let keyCode = "c".keyCode {
            tempKeyCode = keyCode
        }
        
        self.cKeyCode = tempKeyCode
    }
    
    // MARK: - Functions

    func start() {
        stop()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        
        let cKey = self.cKeyCode
        
        timer.setEventHandler {
            let staticText = "OnitToTheMoon"
            let originalContent = ClipboardPoller.readFromPasteboard()
            
            ClipboardPoller.writeToPasteboard(staticText)
            
            usleep(10000)
            
            if ClipboardPoller.copyToClipboard(keyCode: cKey) {
                let newContent = ClipboardPoller.readFromPasteboardWithRetry(previousContent: staticText)
                
                ClipboardPoller.writeToPasteboard(originalContent)
                
                if !newContent.isEmpty && newContent != staticText {
                    DispatchQueue.main.async {
                        let state = OnitPanelStateCoordinator.shared.state
                        if newContent != state.pendingInput?.selectedText {
                            state.pendingInput = Input(selectedText: newContent, application: nil)
                        }
                    }
                }
            }
        }
        timer.resume()
        
        self.timer = timer
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    private static func copyToClipboard(keyCode: CGKeyCode) -> Bool {
        guard let cmdCDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let cmdCUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return false
        }
        
        cmdCDown.flags = .maskCommand
        cmdCUp.flags = .maskCommand
        
        cmdCDown.post(tap: .cghidEventTap)
        cmdCUp.post(tap: .cghidEventTap)
        
        return true
    }
    
    private static func readFromPasteboardWithRetry(previousContent: String, maxAttempts: Int = 10, initialDelay: UInt32 = 50000) -> String {
        var content = ""
        var attempts = 0
        
        usleep(initialDelay)
        content = Self.readFromPasteboard()
        
        while (content == previousContent || content.isEmpty) && attempts < maxAttempts {
            let delay = initialDelay * UInt32(attempts + 2)
            usleep(delay)
            
            let newContent = Self.readFromPasteboard()
            
            if newContent != previousContent && !newContent.isEmpty {
                content = newContent
                break
            }
            
            attempts += 1
        }
        
        if content == previousContent {
            return ""
        }
        
        return content
    }
    
    private static func readFromPasteboard() -> String {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) ?? ""
    }
    
    private static func writeToPasteboard(_ content: String) {
        guard !content.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if !pasteboard.setString(content, forType: .string) {
            DispatchQueue.main.async {
                log.error("Failed to set text to pasteboard")
            }
        }
    }
}

//
//  TypeaheadSessionManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

//struct TypingSession {
//    var initialText: String = ""
//    var currentText: String = ""
//    var startTime: Date = Date()
//    var lastKeystroke: Date = Date()
//    var element: AXUIElement?
//    var elementId: UInt?
//    
//    // TODO: Tim - keep a list of the keystrokes that got us from initialText to currentText. 
//
//    mutating func updateText(_ newText: String) {
//        currentText = newText
//        lastKeystroke = Date()
//    }
//    
//    var timeSinceLastKeystroke: TimeInterval {
//        Date().timeIntervalSince(lastKeystroke)
//    }
//    
//    var totalDuration: TimeInterval {
//        Date().timeIntervalSince(startTime)
//    }
//    
//    var hasChanged: Bool {
//        return initialText != currentText
//    }
//    
//}
//
//
//final class TypeaheadSessionManager {
//
//    private var currentSession: TypingSession?

    // So the logic to do here is: 

    // I think the event streams should be managed by this class. 
    

    // The important logic to implement is:
    // When a new keystroke comes in and we don't have a session...
        // We should run the startSession logic that looks for the 'startText' in the buffer
        // If it's not there, we can wait.
        // While we're waiting, if more keystroke events come in, we should enqueue them.
        // If we stop waiting at any point, process all of thems that are in the queue.
    

    // So the API is:

    // Add new value
    // Start a new session. 
    
    // The data store needs to have: 
    // The buffer of values. 


    // 
 //    func startNewSession(afterText: String) {

//}   

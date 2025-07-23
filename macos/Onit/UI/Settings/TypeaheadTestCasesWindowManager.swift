import SwiftUI
import AppKit

@MainActor
class TypeaheadTestCasesWindowManager: ObservableObject {
    static let shared = TypeaheadTestCasesWindowManager()
    
    private var window: NSWindow?
    
    private init() {}
    
    func showWindow() {
        // Close existing window if it exists
        closeWindow()
        
        // Create new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Typeahead Test Cases"
        window.center()
        window.setFrameAutosaveName("TypeaheadTestCasesWindow")
        
        // Create the SwiftUI view
        let contentView = TypeaheadTestCasesWindow(onClose: {
            self.closeWindow()
        })
        
        window.contentView = NSHostingView(rootView: contentView)
        
        // Store reference and show window
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeWindow() {
        window?.close()
        window = nil
    }
    
    func isWindowOpen() -> Bool {
        return window != nil && window?.isVisible == true
    }
} 
//
//  HighlightedTextBoundTrainingSampleDetailWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 06/27/2025.
//

import SwiftUI
import AppKit

class HighlightedTextBoundTrainingSampleDetailWindowController: NSWindowController {
    private var hostingController: NSHostingController<HighlightedTextBoundTrainingSampleDetailView>?
    
    convenience init(sample: HighlightedTextBoundTrainingSample, onSave: @escaping (HighlightedTextBoundTrainingSample) -> Void, onDelete: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("TrainingSampleDetailWindow")
        
        self.init(window: window)
        
        let detailView = HighlightedTextBoundTrainingSampleDetailView(
            sample: sample,
            onSave: onSave,
            onDelete: onDelete,
            onClose: { [weak self] in
                self?.window?.close()
            }
        )
        
        hostingController = NSHostingController(rootView: detailView)
        window.contentViewController = hostingController
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
} 

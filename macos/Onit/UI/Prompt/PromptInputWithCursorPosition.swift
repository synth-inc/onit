//
//  PromptInputWithCursorPosition.swift
//  Onit
//
//  Created by Loyd Kim on 4/22/25.
//

import SwiftUI

struct PromptInputWithCursorPosition: NSViewRepresentable {
    @Binding var text: String
    var onCursorPositionChange: (Int) -> Void
    
    func makeNSView(context: Self.Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator // Required for cursor positioning logic.
        textView.isRichText = false // Ensures plain text only. Prevents unexpected formatting behavior.
        textView.font = AppFont.medium16.nsFont // Remove this if system default font is okay.
        textView.textColor = .white
        textView.drawsBackground = false // Makes the text view's background transparent.
        textView.insertionPointColor = .white
        textView.isEditable = true // Required for text input fields.
        textView.isSelectable = true // Allows for normal text interaction.
        textView.string = text // Initializes text view with `windowState.pendingInstruction`.
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Self.Context) {
        let textView = nsView.documentView as! NSTextView
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        
        // Move cursor to the end of the text
        let endRange = NSRange(location: text.count, length: 0)
        textView.setSelectedRange(endRange)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PromptInputWithCursorPosition
        
        init(_ parent: PromptInputWithCursorPosition) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let cursorPosition = textView.selectedRange().location
            parent.onCursorPositionChange(cursorPosition)
        }
    }
}

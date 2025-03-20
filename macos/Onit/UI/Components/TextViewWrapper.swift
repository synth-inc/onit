//
//  TextViewWrapper.swift
//  Onit
//
//  Created by Kévin Naudin on 16/02/2025.
//

import Defaults
import SwiftUI

/// A custom TextView which :
/// - Works like a TextField - press enter will call `onSubmit`
/// - Has a dynamic height that is limited by `maxHeight`, when max height is reached the content become scrollable
/// - Manage a placeholder
/// - Can show a waveform indicator at the end of text when recording
struct TextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    @Binding var dynamicHeight: CGFloat
    var onSubmit: (() -> Void)? = nil
    var maxHeight: CGFloat? = nil
    var placeholder: String? = nil
    var audioRecorder: AudioRecorder
    
    var font: NSFont = AppFont.medium16.nsFont
    var textColor: NSColor = .white
    var placeholderColor: NSColor = .gray300

    func makeNSView(context: Self.Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CustomTextView(text: text,
                                      customFont: font,
                                      textColor: textColor,
                                      placeholderColor: placeholderColor,
                                      placeholder: placeholder,
                                      audioRecorder: audioRecorder)
        
        textView.delegate = context.coordinator
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.verticalScrollElasticity = .none
        scrollView.hasVerticalRuler = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true
        context.coordinator.textView = textView
        
        /// First time the view appear with huge text
        /// We should update the height and the scroll inset
        DispatchQueue.main.async {
            context.coordinator.updateHeight()
            
            let contentHeight = textView.frame.height
            let visibleHeight = scrollView.contentView.bounds.height
            let newY = max(0, contentHeight - visibleHeight)
            
            scrollView.contentView.scroll(NSPoint(x: 0, y: newY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Self.Context) {
        guard let textView = nsView.documentView as? CustomTextView else { return }
        
        if let maxHeight = maxHeight {
            nsView.hasVerticalScroller = dynamicHeight > maxHeight
        }
        
        // Update waveform and loading state
        textView.audioRecorder = audioRecorder
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            
            if !text.isEmpty {
                let range = NSRange(location: 0, length: text.count)
                textView.setTextColor(textColor, range: range)
                textView.setFont(font, range: range)
            }
            
            // Move cursor to the end of the text
            let endRange = NSRange(location: text.count, length: 0)
            textView.setSelectedRange(endRange)

            context.coordinator.updateHeight()
        }
        
        // Update the cursor position in the textView
        textView.parentCursorPosition = cursorPosition
        
        // Force redraw when waveform or loading state changes
        if textView.needsDisplay == false {
            textView.needsDisplay = true
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextViewWrapper
        fileprivate weak var textView: CustomTextView?

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = self.textView else { return }
            parent.text = textView.string
            // Only update the cursor position when we're not recording, so we can restore it afterwards.
            if !(parent.audioRecorder.isRecording || parent.audioRecorder.isTranscribing) {
                parent.cursorPosition = textView.selectedRange().location
            }
            
            updateHeight()
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = self.textView as? NSTextView else { return }
            // Only update the cursor position when we're not recording, so we can restore it afterwards.
            if !(parent.audioRecorder.isRecording || parent.audioRecorder.isTranscribing) {
                parent.cursorPosition = textView.selectedRange().location
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit?()
                return true
            }
            return false
        }

        @MainActor func updateHeight() {
            guard let textView = self.textView else { return }
            
            let height = textView.intrinsicContentSize.height
            
            DispatchQueue.main.async {
                self.parent.dynamicHeight = height
            }
        }
    }
}

private class CustomTextView: NSTextView {
    let customFont: NSFont
    let placeholderColor: NSColor
    let placeholder: String?
    @ObservedObject var audioRecorder: AudioRecorder
    var recordingIndicator: NSHostingView<RecordingIndicator>? = nil
    var parentCursorPosition: Int = 0
    
    init(text: String, customFont: NSFont, textColor: NSColor, placeholderColor: NSColor, placeholder: String?, audioRecorder: AudioRecorder) {
        self.customFont = customFont
        self.placeholderColor = placeholderColor
        self.placeholder = placeholder
        self.audioRecorder = audioRecorder

        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        
        super.init(frame: .zero, textContainer: container)
        
        container.widthTracksTextView = true
        container.heightTracksTextView = false
        
        isEditable = true
        isRichText = false
        drawsBackground = false
        
        string = text
        font = customFont
        self.textColor = textColor
        insertionPointColor = textColor
        
        isVerticallyResizable = true
        isHorizontallyResizable = false
        autoresizingMask = [.width]
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        typingAttributes = [
            .font: customFont,
            .foregroundColor: textColor
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Disable typing and hide cursor when recording or loading
        isEditable = !(audioRecorder.isRecording || audioRecorder.isTranscribing)
        insertionPointColor = (audioRecorder.isRecording || audioRecorder.isTranscribing) ? .clear : textColor
        
        if string.isEmpty && !audioRecorder.isRecording && !audioRecorder.isTranscribing, let placeholder = placeholder {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: customFont,
                .foregroundColor: placeholderColor
            ]
            
            let rect = NSRect(x: textContainerInset.width + 5,
                            y: textContainerInset.height,
                            width: bounds.width - textContainerInset.width * 2,
                            height: bounds.height)
            
            placeholder.draw(in: rect, withAttributes: attributes)
        }
        
        // Add padding to the right side of the text field when waveform or loading is shown
        if audioRecorder.isRecording || audioRecorder.isTranscribing {            
            if recordingIndicator == nil {
                let recordingView = RecordingIndicator(audioRecorder: audioRecorder)
                let hostingView = NSHostingView(rootView: recordingView)
                recordingIndicator = hostingView
            }
            
            if let recordingIndicator = recordingIndicator {
                let glyphRange = layoutManager?.glyphRange(forCharacterRange: NSRange(location: parentCursorPosition, length: 0), actualCharacterRange: nil)
                let glyphRect = layoutManager?.boundingRect(forGlyphRange: glyphRange!, in: textContainer!)
                recordingIndicator.frame = NSRect(x: glyphRect!.maxX, y: glyphRect!.minY, width: 33, height: 20)
                if recordingIndicator.superview == nil {
                    addSubview(recordingIndicator)
                }
            }
        } else {
            recordingIndicator?.removeFromSuperview()
            recordingIndicator = nil
        }
    }
    
    override var intrinsicContentSize: NSSize {
        guard let container = textContainer,
              let layoutManager = layoutManager else {
            return super.intrinsicContentSize
        }
        
        layoutManager.ensureLayout(for: container)
        
        let usedRect = layoutManager.usedRect(for: container)
        return NSSize(
            width: frame.width,
            height: ceil(usedRect.height + textContainerInset.height * 2)
        )
    }
    
    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
}

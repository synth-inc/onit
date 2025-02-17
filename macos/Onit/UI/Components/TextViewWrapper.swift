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
struct TextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    var onSubmit: (() -> Void)? = nil
    var maxHeight: CGFloat? = nil
    var placeholder: String? = nil
    
    var font: NSFont = AppFont.medium16.nsFont
    var textColor: NSColor = .white
    var placeholderColor: NSColor = .gray300

    func makeNSView(context: Self.Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CustomTextView(text: text,
                                      customFont: font,
                                      textColor: textColor,
                                      placeholderColor: placeholderColor,
                                      placeholder: placeholder)
        
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
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            
            if !text.isEmpty {
                let range = NSRange(location: 0, length: text.count)
                textView.setTextColor(textColor, range: range)
                textView.setFont(font, range: range)
            }
            
            context.coordinator.updateHeight()
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
            updateHeight()
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
    
    init(text: String, customFont: NSFont, textColor: NSColor, placeholderColor: NSColor, placeholder: String?) {
        self.customFont = customFont
        self.placeholderColor = placeholderColor
        self.placeholder = placeholder
        
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
        
        if string.isEmpty, let placeholder = placeholder {
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

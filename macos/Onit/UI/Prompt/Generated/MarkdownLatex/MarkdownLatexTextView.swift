//
//  MarkdownLatexTextView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import Highlightr
import SwiftUI

class MarkdownLatexTextView: NSView {
    private let textView: NSTextView
    @MainActor private let parser: MarkdownLatexParser
    private let fontSize: CGFloat
    private let lineHeight: CGFloat
    
    init(text: String, fontSize: CGFloat, lineHeight: CGFloat) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        
        // Setup text container
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 0
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        // Setup text storage with custom parser
        parser = MarkdownLatexParser()
        let textStorage = MarkdownLatexTextStorage(parser: parser)
        textStorage.addLayoutManager(layoutManager)
        
        // Setup text view
        textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.textColor = .white
        textView.drawsBackground = true
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.autoresizingMask = [.width]
        
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = .clear
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        
        setText(text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String) {
        Task { @MainActor in
            print(text)
            let elements = await parser.parse(text)
            let attributedString = NSMutableAttributedString()
            
            let defaultParagraphStyle = NSMutableParagraphStyle()
            defaultParagraphStyle.lineSpacing = (lineHeight * fontSize) - fontSize
            defaultParagraphStyle.paragraphSpacing = fontSize
            
            for element in elements {
                switch element {
                case .text(let str):
                    print("KNA - Text")
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: fontSize),
                        .foregroundColor: NSColor.white,
                        .paragraphStyle: defaultParagraphStyle
                    ]
                    attributedString.append(NSAttributedString(string: str, attributes: attrs))
                    
                case .code(let code, let language):
                    print("KNA - Code")
                    if attributedString.length > 0 && !attributedString.string.hasSuffix("\n") {
                        attributedString.append(NSAttributedString(string: "\n", attributes: [:]))
                    }
                    let codeBlock = createCodeBlock(code: code, language: language)
                    attributedString.append(codeBlock)
                    if !attributedString.string.hasSuffix("\n") {
                        attributedString.append(NSAttributedString(string: "\n", attributes: [:]))
                    }
                    
                case .latex(let latex):
                    print("KNA - Latex")
                    if attributedString.length > 0 && !attributedString.string.hasSuffix("\n") {
                        attributedString.append(NSAttributedString(string: "\n", attributes: [:]))
                    }
                    
                    let attachmentParagraphStyle = NSMutableParagraphStyle()
                    attachmentParagraphStyle.lineSpacing = fontSize
                    attachmentParagraphStyle.paragraphSpacing = fontSize
                    attachmentParagraphStyle.alignment = .left
                    
                    let attachment = createLatexView(latex: latex)
                    let attachmentString = NSMutableAttributedString(string: "\u{fffc}")
                    let fullRange = NSRange(location: 0, length: attachmentString.length)
                    attachmentString.addAttributes([
                        .attachment: attachment,
                        .paragraphStyle: attachmentParagraphStyle
                    ], range: fullRange)
                    attributedString.append(attachmentString)
                    
                    if !attributedString.string.hasSuffix("\n") {
                        attributedString.append(NSAttributedString(string: "\n", attributes: [:]))
                    }
                }
            }
            
            self.textView.textStorage?.setAttributedString(attributedString)
            
            self.textView.layoutManager?.ensureLayout(for: self.textView.textContainer!)
            self.textView.layoutManager?.glyphRange(for: self.textView.textContainer!)
            
            if let layoutManager = self.textView.layoutManager {
                let usedRect = layoutManager.usedRect(for: self.textView.textContainer!)
                let newHeight = ceil(usedRect.height + self.textView.textContainerInset.height * 2)
                self.frame = NSRect(x: 0, y: 0, width: bounds.width, height: newHeight)
                self.textView.frame = bounds
            }
            
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: NSSize {
        guard let layoutManager = textView.layoutManager else {
            return super.intrinsicContentSize
        }
        let usedRect = layoutManager.usedRect(for: textView.textContainer!)
        return NSSize(width: NSView.noIntrinsicMetric, height: usedRect.height)
    }
    
    private func createCodeBlock(code: String, language: String?) -> NSAttributedString {
        let highlighter = Highlightr()!
        highlighter.setTheme(to: "monokai")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.firstLineHeadIndent = 16
        paragraphStyle.headIndent = 16
        paragraphStyle.tailIndent = -16
        
        guard let highlighted = highlighter.highlight(code, as: language ?? "swift") else {
            // Fallback if highlighting fails
            return NSAttributedString(string: code, attributes: [
                .font: NSFont(name: "SometypeMono-Regular", size: fontSize - 1) ?? NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular),
                .backgroundColor: NSColor.black.withAlphaComponent(0.3),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ])
        }
        
        // Create mutable copy to modify attributes
        let mutable = NSMutableAttributedString(attributedString: highlighted)
        
        // Add newlines before and after with default style
        let defaultStyle = NSMutableParagraphStyle()
        defaultStyle.paragraphSpacing = fontSize / 2
        
        let beforeNewline = NSAttributedString(string: "\n", attributes: [.paragraphStyle: defaultStyle])
        let afterNewline = NSAttributedString(string: "\n", attributes: [.paragraphStyle: defaultStyle])
        
        let result = NSMutableAttributedString()
        result.append(beforeNewline)
        
        // Apply our custom attributes while preserving syntax colors
        mutable.enumerateAttributes(in: NSRange(location: 0, length: mutable.length), options: []) { attrs, range, _ in
            var newAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "SometypeMono-Regular", size: fontSize - 1) ?? NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular),
                .backgroundColor: NSColor.black.withAlphaComponent(0.3),
                .paragraphStyle: paragraphStyle
            ]
            
            // Preserve the syntax highlighting color if it exists, else use brightless one
            if let color = attrs[.foregroundColor] as? NSColor {
                if color.brightnessComponent < 0.2 {
                    newAttrs[.foregroundColor] = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
                } else {
                    newAttrs[.foregroundColor] = color
                }
            } else {
                newAttrs[.foregroundColor] = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            }
            
            mutable.setAttributes(newAttrs, range: range)
        }
        
        result.append(mutable)
        result.append(afterNewline)
        
        return result
    }
    
    private func createLatexView(latex: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let cell = LaTeXAttachmentCell(latex: latex, fontSize: fontSize)
        attachment.attachmentCell = cell
        return attachment
    }
    
    override func layout() {
        super.layout()
        textView.textContainer?.size = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
    }
}

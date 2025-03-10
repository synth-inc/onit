//
//  CodeBlockAttachmentCell.swift
//  Onit
//
//  Created by Kévin Naudin on 09/03/2025.
//

import AppKit

class CodeBlockAttachmentCell: NSTextAttachmentCell {
    private let codeBlockView: CodeBlockView
    private var lastFrame: NSRect = .zero
    private var cellID = UUID().uuidString.prefix(6)
    private var exactHeight: CGFloat?
    
    init(codeBlockView: CodeBlockView) {
        self.codeBlockView = codeBlockView
        
        super.init(imageCell: NSImage())
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setExactHeight(_ height: CGFloat) {
        self.exactHeight = height
    }
    
    override func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        return MainActor.assumeIsolated {
            let height = exactHeight ?? codeBlockView.intrinsicContentSize.height
            
            lastFrame = NSRect(x: 0, y: 0, width: lineFrag.width, height: height)
            
            return NSRect(x: 0, y: 0, width: lineFrag.width, height: height)
        }
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?, characterIndex charIndex: Int, layoutManager: NSLayoutManager) {
        var adjustedFrame = lastFrame
        
        adjustedFrame.origin = cellFrame.origin
        codeBlockView.frame = adjustedFrame
        
        if let textView = controlView as? NSTextView {
            if codeBlockView.superview == nil {
                textView.addSubview(codeBlockView)
                
                codeBlockView.layoutSubtreeIfNeeded()
            }
        }
    }
    
    deinit {
        let viewToRemove = codeBlockView
        let cellID = cellID
        DispatchQueue.main.async {
            if viewToRemove.superview != nil {
                viewToRemove.removeFromSuperview()
            }
        }
    }
} 

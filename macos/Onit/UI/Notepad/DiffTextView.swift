//
//  DiffTextView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/09/2025.
//

import SwiftUI
import AppKit
import SwiftData

class ScrollDetectorScrollView: NSScrollView {
    var onScrollStart: (() -> Void)?
    var onScrollEnd: (() -> Void)?
    private var scrollTimer: Timer?
    
    override func scrollWheel(with event: NSEvent) {
        onScrollStart?()
        
        scrollTimer?.invalidate()
        
        super.scrollWheel(with: event)
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            DispatchQueue.main.async {
                self.onScrollEnd?()
            }
        }
    }
}

class ClickableTextView: NSTextView {
    var onTextClicked: ((Int) -> Void)?
    var segments: [DiffSegment] = []
    var effectiveChanges: [DiffChangeData] = []
    
    override func mouseDown(with event: NSEvent) {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer,
              let textStorage = textStorage else {
            super.mouseDown(with: event)
            return
        }
        
        let location = convert(event.locationInWindow, from: nil)
        let adjustedLocation = CGPoint(
            x: location.x - textContainerInset.width,
            y: location.y - textContainerInset.height
        )
        let characterIndex = layoutManager.characterIndex(for: adjustedLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex >= 0 && characterIndex < textStorage.length else {
            super.mouseDown(with: event)
            return
        }
        
        var currentIndex = 0
        
        for (_, segment) in segments.enumerated() {
            let segmentStatus: DiffChangeStatus? = {
                guard let opIndex = segment.operationIndex else { return nil }
                return effectiveChanges.first { $0.operationIndex == opIndex }?.status
            }()
            let isSegmentVisible = DiffSegmentUtils.shouldSegmentBeVisible(segment: segment, status: segmentStatus)
            
            if isSegmentVisible {
                let segmentRange = NSRange(location: currentIndex, length: segment.content.count)
                
                if segmentRange.contains(characterIndex) {
                    if let operationIndex = segment.operationIndex {
                        if segmentStatus == .pending {
                            onTextClicked?(operationIndex)
                            return
                        }
                    }
                    return
                }
                
                currentIndex += segment.content.count
            }
        }
        
        super.mouseDown(with: event)
    }
}

struct DiffTextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    let segments: [DiffSegment]
    let currentOperationIndex: Int
    let effectiveChanges: [DiffChangeData]
    let onSegmentPositionChanged: (CGRect?) -> Void
    let onSegmentClicked: (Int) -> Void
    let shouldScrollToCurrentSegment: Bool
    let onScrollStateChanged: (Bool) -> Void
    
    func makeNSView(context: Self.Context) -> NSScrollView {
        let scrollView = ScrollDetectorScrollView()
        let textView = ClickableTextView()
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        guard let textContainer = textView.textContainer else {
            return scrollView
        }
        
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = true
        textContainer.containerSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.drawsBackground = false
        textView.isRichText = true
        textView.allowsUndo = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        scrollView.documentView = textView
        
        let attributedText = createNSAttributedText(for: segments)
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        }
        
        textView.segments = segments
        textView.effectiveChanges = effectiveChanges
        textView.onTextClicked = onSegmentClicked
        
        scrollView.onScrollStart = {
            DispatchQueue.main.async {
                self.onScrollStateChanged(true)
            }
        }
        
        scrollView.onScrollEnd = {
            DispatchQueue.main.async {
                self.onScrollStateChanged(false)
                self.calculateCurrentSegmentPosition(textView: textView)
            }
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Self.Context) {
        guard let textView = nsView.documentView as? ClickableTextView,
              let scrollView = nsView as? ScrollDetectorScrollView else { 
            return 
        }
        
        let attributedText = createNSAttributedText(for: segments)
        
        textView.textStorage?.setAttributedString(attributedText)
        
        if let textContainer = textView.textContainer {
            textView.layoutManager?.ensureLayout(for: textContainer)
        }
		
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.calculateCurrentSegmentPosition(textView: textView)
            
            if self.shouldScrollToCurrentSegment {
                self.scrollToCurrentSegment(textView: textView)
            }
        }
        
        textView.segments = segments
        textView.effectiveChanges = effectiveChanges
        textView.onTextClicked = onSegmentClicked
        
        scrollView.onScrollStart = {
            DispatchQueue.main.async {
                self.onScrollStateChanged(true)
            }
        }
        
        scrollView.onScrollEnd = {
            DispatchQueue.main.async {
                self.onScrollStateChanged(false)
                self.calculateCurrentSegmentPosition(textView: textView)
            }
        }
    }

    private func findCurrentSegmentRect(textView: NSTextView) -> CGRect? {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return nil
        }
        
        var characterIndex = 0
        var currentSegmentStart = 0
        var currentSegmentLength = 0
        var foundCurrentSegment = false
        
        for segment in segments {
            let segmentStatus: DiffChangeStatus? = {
                guard let opIndex = segment.operationIndex else { return nil }
                return effectiveChanges.first { $0.operationIndex == opIndex }?.status
            }()
            let isSegmentVisible = DiffSegmentUtils.shouldSegmentBeVisible(segment: segment, status: segmentStatus)
            
            if let segmentOpIndex = segment.operationIndex, segmentOpIndex == currentOperationIndex && isSegmentVisible {
                currentSegmentStart = characterIndex
                currentSegmentLength = segment.content.count
                foundCurrentSegment = true
                break
            }
            
            if isSegmentVisible {
                characterIndex += segment.content.count
            }
        }
        
        guard foundCurrentSegment && currentSegmentLength > 0 else {
            return nil
        }
        
        let range = NSRange(location: currentSegmentStart, length: currentSegmentLength)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        return CGRect(
            x: boundingRect.origin.x + textView.textContainerInset.width,
            y: boundingRect.origin.y + textView.textContainerInset.height,
            width: boundingRect.width,
            height: boundingRect.height
        )
    }
    
    private func scrollToCurrentSegment(textView: NSTextView) {
        guard let scrollView = textView.enclosingScrollView,
              let segmentRect = findCurrentSegmentRect(textView: textView) else {
            return
        }
        
        let visibleRect = scrollView.contentView.visibleRect
        let targetY = segmentRect.origin.y - (visibleRect.height / 3)
        let targetPoint = NSPoint(x: 0, y: max(0, targetY))
        
        DispatchQueue.main.async {
            self.onScrollStateChanged(true)
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            scrollView.contentView.animator().setBoundsOrigin(targetPoint)
        } completionHandler: {
            DispatchQueue.main.async {
                self.onScrollStateChanged(false)
                self.calculateCurrentSegmentPosition(textView: textView)
            }
        }
    }
    
    private func calculateCurrentSegmentPosition(textView: NSTextView) {
        guard let segmentRect = findCurrentSegmentRect(textView: textView) else {
            DispatchQueue.main.async {
                self.onSegmentPositionChanged(nil)
            }
            return
        }
        
        let visibleRect = textView.visibleRect
        
        if visibleRect.contains(segmentRect) {
            let scrollViewRect = CGRect(
                x: segmentRect.origin.x,
                y: segmentRect.origin.y - visibleRect.origin.y,
                width: segmentRect.width,
                height: segmentRect.height
            )
            DispatchQueue.main.async {
                self.onSegmentPositionChanged(scrollViewRect)
            }
        } else {
            DispatchQueue.main.async {
                self.onSegmentPositionChanged(nil)
            }
        }
    }
    
    private func createNSAttributedText(for segments: [DiffSegment]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for segment in segments {
            let segmentStatus: DiffChangeStatus? = {
                guard let opIndex = segment.operationIndex else { return nil }
                return effectiveChanges.first { $0.operationIndex == opIndex }?.status
            }()
            let isCurrentSegment = segment.operationIndex == currentOperationIndex
            let font = NSFont.monospacedSystemFont(ofSize: 14,
                                                   weight: isCurrentSegment ? .bold : .regular)
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            
            switch segment.type {
            case .unchanged:
                attributes[.foregroundColor] = NSColor.labelColor
                
            case .added:
                switch segmentStatus {
                case .approved:
                    attributes[.foregroundColor] = NSColor.labelColor
                case .pending:
                    attributes[.foregroundColor] = NSColor.systemGreen
                    attributes[.backgroundColor] = NSColor.systemGreen.withAlphaComponent(0.2)
                case .rejected:
                    continue
                default:
                    attributes[.foregroundColor] = NSColor.secondaryLabelColor
                    attributes[.backgroundColor] = NSColor.secondaryLabelColor.withAlphaComponent(0.1)
                }
                
            case .removed:
                switch segmentStatus {
                case .approved:
                    continue
                case .pending:
                    attributes[.foregroundColor] = NSColor.systemRed
                    attributes[.backgroundColor] = NSColor.systemRed.withAlphaComponent(0.2)
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                case .rejected:
                    attributes[.foregroundColor] = NSColor.labelColor
                default:
                    attributes[.foregroundColor] = NSColor.secondaryLabelColor
                    attributes[.backgroundColor] = NSColor.secondaryLabelColor.withAlphaComponent(0.1)
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
            }
            
            let segmentText = NSAttributedString(string: segment.content, attributes: attributes)
            result.append(segmentText)
        }
        
        // Add bottom spacing to prevent text from being hidden by bottom views
        let spacingAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.clear
        ]
        let spacingText = NSAttributedString(string: "\n\n\n\n\n\n\n", attributes: spacingAttributes)
        result.append(spacingText)
        
        return result
    }
}

extension DiffTextView {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: DiffTextView
        
        init(_ parent: DiffTextView) {
            self.parent = parent
        }
    }
} 

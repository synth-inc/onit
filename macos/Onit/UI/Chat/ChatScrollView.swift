//
//  ChatScrollView.swift
//  Onit
//
//  Created by Kévin Naudin on 03/06/2025.
//

import AppKit
import SwiftUI

class ChatScrollView: NSScrollView {
    
    private var autoScrollTimer: Timer?
    private var autoScrollTimeoutTimer: Timer?
    private var isAutoScrolling: Bool = false
    private var lastScrollPosition: CGFloat = 0
    
    private var lastContentHeight: CGFloat = 0
    private var shouldCompensateGrowth: Bool = false
    private var frozenScrollPosition: CGFloat = 0
    
    private var _hasUserManuallyScrolled: Bool = false {
        didSet {
            onUserScrollStateChanged?(_hasUserManuallyScrolled)

            if _hasUserManuallyScrolled && oldValue == false {
                enableContentGrowthCompensation()
            } else if !_hasUserManuallyScrolled && oldValue == true {
                disableContentGrowthCompensation()
            }
        }
    }
    
    var hasUserManuallyScrolled: Bool {
        return _hasUserManuallyScrolled
    }
    
    var onUserScrollStateChanged: ((Bool) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupScrollView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }
    
    private func setupScrollView() {
        hasVerticalScroller = true
        hasHorizontalScroller = false
        autohidesScrollers = true
        
        drawsBackground = false
        backgroundColor = .clear
        
        lastScrollPosition = 0
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidLiveScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: self
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Auto Scroll Logic
    
    func startAutoScrolling() {
        guard !_hasUserManuallyScrolled else { return }
        
        if isAutoScrolling {
            resetAutoScrollTimeout()
            return
        }
        
        stopAutoScrolling()
        isAutoScrolling = true
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.scrollToBottom()
            }
        }
        
        scrollToBottom()
        resetAutoScrollTimeout()
    }
    
    private func resetAutoScrollTimeout() {
        autoScrollTimeoutTimer?.invalidate()
        autoScrollTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopAutoScrolling()
            }
        }
    }
    
    func stopAutoScrolling() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        autoScrollTimeoutTimer?.invalidate()
        autoScrollTimeoutTimer = nil
        isAutoScrolling = false
    }
    
    func scrollToBottom(animated: Bool = true) {
        guard let documentView = documentView else { return }
        
        let contentHeight = documentView.frame.height
        let clipHeight = contentView.frame.height
        let maxY = max(0, contentHeight - clipHeight)
        
        let targetPoint = NSPoint(x: 0, y: maxY)
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                contentView.animator().setBoundsOrigin(targetPoint)
            }
        } else {
            contentView.setBoundsOrigin(targetPoint)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.lastScrollPosition = self?.documentVisibleRect.origin.y ?? 0
        }
    }
    
    func resetUserScrollState() {
        _hasUserManuallyScrolled = false
        startAutoScrolling()
    }
    
    // MARK: - Manual Scroll Detection
    
    @objc private func scrollViewDidLiveScroll(_ notification: Notification) {
        guard let scrollView = notification.object as? NSScrollView,
              scrollView == self else { return }
        
        detectScrollDirection()
    }
    
    private func detectScrollDirection() {
        guard let documentView = documentView else { return }
        
        let visibleRect = documentVisibleRect
		let currentScrollPosition = visibleRect.origin.y
        let scrollDirection = currentScrollPosition - lastScrollPosition
        
        if isAutoScrolling && scrollDirection >= 0 {
            lastScrollPosition = currentScrollPosition
            return
        }
        
        let contentHeight = documentView.frame.height
        let maxScrollPosition = max(0, contentHeight - visibleRect.height)
        let distanceFromBottom = contentHeight - (visibleRect.origin.y + visibleRect.height)
        let isInElasticZone = currentScrollPosition < 0 || currentScrollPosition > maxScrollPosition
        
        if scrollDirection > 5 {
            if distanceFromBottom <= 50 || (distanceFromBottom <= 100 && isInElasticZone) {
                _hasUserManuallyScrolled = false
            	startAutoScrolling()
            }
        }
        if isInElasticZone {
            lastScrollPosition = currentScrollPosition
            return
        }
        if scrollDirection < -5 {
            _hasUserManuallyScrolled = true
            stopAutoScrolling()
        }
        
        if _hasUserManuallyScrolled && shouldCompensateGrowth {
            frozenScrollPosition = currentScrollPosition
        }
        
        lastScrollPosition = currentScrollPosition
    }
    
    // MARK: - Content Growth Compensation
    
    private func enableContentGrowthCompensation() {
        guard let documentView = documentView else { return }
        
        shouldCompensateGrowth = true
        lastContentHeight = documentView.frame.height
        
        let visibleRect = documentVisibleRect
        frozenScrollPosition = visibleRect.origin.y
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentViewFrameDidChange),
            name: NSView.frameDidChangeNotification,
            object: documentView
        )
    }
    
    private func disableContentGrowthCompensation() {
        shouldCompensateGrowth = false
        
        if let documentView = documentView {
            NotificationCenter.default.removeObserver(
                self,
                name: NSView.frameDidChangeNotification,
                object: documentView
            )
        }
    }
    
    @objc private func documentViewFrameDidChange(_ notification: Notification) {
        guard shouldCompensateGrowth,
              let documentView = notification.object as? NSView,
              documentView == self.documentView else { return }
        
        let currentContentHeight = documentView.frame.height
        let heightDelta = currentContentHeight - lastContentHeight
        
        if heightDelta > 5 {
            let currentBounds = contentView.bounds
            
            contentView.setBoundsOrigin(NSPoint(x: currentBounds.origin.x, y: frozenScrollPosition))
            lastScrollPosition = frozenScrollPosition
        }
        
        lastContentHeight = currentContentHeight
    }
}

// MARK: - SwiftUI Wrapper

struct ChatScrollViewRepresentable: NSViewRepresentable {
    @Binding var hasUserManuallyScrolled: Bool
    
    let streamedResponse: String
    let currentChat: Any?
    let content: AnyView
    
    init<Content: View>(
        hasUserManuallyScrolled: Binding<Bool>,
        streamedResponse: String,
        currentChat: Any?,
        @ViewBuilder content: () -> Content
    ) {
        self._hasUserManuallyScrolled = hasUserManuallyScrolled
        self.streamedResponse = streamedResponse
        self.currentChat = currentChat
        self.content = AnyView(content())
    }
    
    func makeNSView(context: Self.Context) -> ChatScrollView {
        let scrollView = ChatScrollView()
        
        let hostController = NSHostingController(rootView: content)
        let hostView = hostController.view
        hostView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = hostView
        
        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            hostView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
        
        scrollView.onUserScrollStateChanged = { hasUserScrolled in
            DispatchQueue.main.async {
                hasUserManuallyScrolled = hasUserScrolled
            }
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: ChatScrollView, context: Self.Context) {
        let shouldStartAutoScroll = !streamedResponse.isEmpty
        
        if hasUserManuallyScrolled {
            nsView.stopAutoScrolling()
        } else if shouldStartAutoScroll {
            nsView.startAutoScrolling()
        }
        
        if !hasUserManuallyScrolled && nsView.hasUserManuallyScrolled {
            nsView.resetUserScrollState()
        }
        
        if let hostController = nsView.documentView?.nextResponder as? NSHostingController<AnyView> {
            hostController.rootView = content
        }
    }
}

//
//  LaTeXView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import SwiftUI
import WebKit
import AppKit

class LaTeXView: WKWebView, WKUIDelegate, WKNavigationDelegate {
    private let fontSize: CGFloat
    private var pendingLatex: String?
    private var messageHandler: ScriptMessageHandler?
    private var onSizeChanged: ((NSSize) -> Void)?
    
    init(latex: String, fontSize: CGFloat, onSizeChanged: ((NSSize) -> Void)? = nil) {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.suppressesIncrementalRendering = false
        config.allowsAirPlayForMediaPlayback = false
        config.mediaTypesRequiringUserActionForPlayback = .all
        
        config.processPool = WKProcessPool()
        
        let contentController = WKUserContentController()
        config.userContentController = contentController

        self.fontSize = fontSize
        self.pendingLatex = latex
        self.onSizeChanged = onSizeChanged
        
        let initialFrame = NSRect(x: 0, y: 0, width: 200, height: fontSize * 3)
        super.init(frame: initialFrame, configuration: config)
        
        setupMessageHandler(contentController)
        
        setValue(false, forKey: "drawsBackground")
        allowsMagnification = true
        
        if let scrollView = self.subviews.first as? NSScrollView {
            let passthroughScrollView = PassthroughScrollView(frame: scrollView.frame)
            passthroughScrollView.documentView = scrollView.documentView
            passthroughScrollView.hasVerticalScroller = false
            passthroughScrollView.hasHorizontalScroller = false
            passthroughScrollView.autoresizingMask = [.width, .height]
            
            scrollView.removeFromSuperview()
            self.addSubview(passthroughScrollView)
        }
        
        navigationDelegate = self
        uiDelegate = self
        
        loadTemplate()
    }
    
    private func loadTemplate() {
        guard let templateURL = Bundle.main.url(forResource: "latex_template", withExtension: "html") else {
            print("Error: Could not find latex_template.html")
            return
        }
        
        do {
            var template = try String(contentsOf: templateURL, encoding: .utf8)
            template = String(format: template, fontSize)
            loadHTMLString(template, baseURL: Bundle.main.bundleURL)
        } catch {
            print("Error loading template:", error)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageHandler(_ contentController: WKUserContentController) {
        let mathjaxHandler = ScriptMessageHandler { [weak self] _ in
            self?.renderPendingLatex()
        }
        let contentProcessedHandler = ScriptMessageHandler { [weak self] _ in
            self?.updateContentSize()
        }
        
        self.messageHandler = mathjaxHandler
        contentController.add(mathjaxHandler, name: "mathjaxReady")
        contentController.add(contentProcessedHandler, name: "contentProcessed")
    }
    
    private func renderPendingLatex() {
        guard let latex = pendingLatex else { return }
        
        let cleanLatex = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "`", with: "\\`")
        
        Task { @MainActor in
            do {
                try await evaluateJavaScript("window.processLatexContent(\"\(cleanLatex)\")")
                pendingLatex = nil
            } catch {
                print("Error rendering LaTeX:", error)
            }
        }
    }
    
    private func updateContentSize() {
        Task {
            try? await evaluateJavaScript("""
                document.body.style.overflow = 'hidden';
                document.documentElement.style.overflow = 'hidden';
            """)
            
            let result = try? await evaluateJavaScript("""
                (function() {
                    const formula = document.getElementById('formula');
                    const blocks = formula.getElementsByClassName('latex-block');
                    let totalHeight = 0;
                    let maxWidth = 0;
                    
                    const formulaRect = formula.getBoundingClientRect();
                    totalHeight = formulaRect.height;
                    maxWidth = formulaRect.width;
                    
                    totalHeight += 10;
                    
                    return [maxWidth, totalHeight];
                })()
            """) as? [CGFloat]
            
            await MainActor.run {
                if let dimensions = result, dimensions.count == 2 {
                    let minHeight = self.fontSize * 3
                    let newSize = NSSize(
                        width: max(dimensions[0], bounds.width),
                        height: max(dimensions[1], minHeight)
                    )
                    
                    self.frame = NSRect(origin: .zero, size: newSize)
                    
                    self.onSizeChanged?(newSize)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
        updateContentSize()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView failed to load:", error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView failed provisional navigation:", error)
    }
    
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}

// MARK: - LaTeX Attachment Cell
class LaTeXAttachmentCell: NSTextAttachmentCell {
    private let latex: String
    private let fontSize: CGFloat
    private lazy var latexView: LaTeXView = {
        let view = LaTeXView(latex: latex, fontSize: fontSize) { [weak self] newSize in
            guard let self = self else { return }
            self.currentSize = newSize
            
            if let textContainer = self.control?.enclosingScrollView?.documentView as? NSTextView {
                textContainer.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textContainer.textStorage?.length ?? 0), actualCharacterRange: nil)
                textContainer.layoutManager?.ensureLayout(for: textContainer.textContainer!)
                textContainer.needsLayout = true
                textContainer.needsDisplay = true
            }
            
            self.control?.needsDisplay = true
        }
        return view
    }()
    
    private var currentSize = NSSize(width: 200, height: 100)
    private weak var control: NSView?
    
    init(latex: String, fontSize: CGFloat) {
        self.latex = latex
        self.fontSize = fontSize
        super.init()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        self.control = controlView
        
        let newFrame = NSRect(
            x: cellFrame.origin.x,
            y: cellFrame.origin.y,
            width: controlView?.bounds.width ?? cellFrame.width,
            height: max(currentSize.height, fontSize * 3)
        )
        
        if latexView.superview == nil {
            controlView?.addSubview(latexView)
            latexView.frame = newFrame
        } else {
            latexView.frame = newFrame
        }
    }
    
    override func cellSize() -> NSSize {
        return MainActor.assumeIsolated {
            NSSize(
                width: control?.bounds.width ?? currentSize.width,
                height: max(currentSize.height, fontSize * 3)
            )
        }
    }
    
    override func cellBaselineOffset() -> NSPoint {
        return NSPoint(x: 0, y: 0)
    }
}

private class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private let callback: (WKScriptMessage) -> Void
    
    init(callback: @escaping (WKScriptMessage) -> Void) {
        self.callback = callback
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        callback(message)
    }
}

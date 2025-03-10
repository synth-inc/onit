//
//  LatexView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import SwiftUI
import WebKit
import AppKit

class LatexView: WKWebView, WKUIDelegate, WKNavigationDelegate {
    private let fontSize: CGFloat
    private var pendingLatex: String?
    private var messageHandler: ScriptMessageHandler?
    private var onSizeChanged: ((NSSize) -> Void)?
    private let viewID = UUID().uuidString.prefix(6)
    
    // Propriétés configurables
    var minHeight: CGFloat = 0 // Sera initialisée dans init
    var extraPadding: CGFloat = 10
    var heightPreset: Bool = false
    var exactHeight: CGFloat?
    
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
        self.minHeight = fontSize * 2 // Réduit de 3 à 2
        
        let initialFrame = NSRect(x: 0, y: 0, width: 200, height: fontSize * 2) // Réduit de 3 à 2
        super.init(frame: initialFrame, configuration: config)
        
        print("KNA - [\(viewID)] Created LaTeXView with latex: \(latex.prefix(30))..., fontSize: \(fontSize)")
        
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
            print("KNA - [\(viewID)] Replaced default scrollView with PassthroughScrollView")
        }
        
        navigationDelegate = self
        uiDelegate = self
        
        loadTemplate()
    }
    
    private func loadTemplate() {
        guard let templateURL = Bundle.main.url(forResource: "latex_template", withExtension: "html") else {
            print("KNA - [\(viewID)] Error: Could not find latex_template.html")
            return
        }
        
        do {
            var template = try String(contentsOf: templateURL, encoding: .utf8)
            template = String(format: template, fontSize)
            loadHTMLString(template, baseURL: Bundle.main.bundleURL)
            print("KNA - [\(viewID)] Loaded HTML template with fontSize: \(fontSize)")
        } catch {
            print("KNA - [\(viewID)] Error loading template:", error)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageHandler(_ contentController: WKUserContentController) {
        let mathjaxHandler = ScriptMessageHandler { [weak self] _ in
            guard let self = self else { return }
            print("KNA - [\(self.viewID)] Received mathjaxReady message")
            self.renderPendingLatex()
        }
        let contentProcessedHandler = ScriptMessageHandler { [weak self] _ in
            guard let self = self else { return }
            print("KNA - [\(self.viewID)] Received contentProcessed message")
            self.updateContentSize()
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
        
        print("KNA - [\(viewID)] Rendering LaTeX content")
        
        Task { @MainActor in
            do {
                try await evaluateJavaScript("window.processLatexContent(\"\(cleanLatex)\")")
                pendingLatex = nil
                print("KNA - [\(viewID)] Successfully processed LaTeX content")
            } catch {
                print("KNA - [\(viewID)] Error rendering LaTeX:", error)
            }
        }
    }
    
    private func updateContentSize() {
        // Si une hauteur exacte a été définie, l'utiliser
        if heightPreset, let exactHeight = exactHeight {
            print("KNA - [\(viewID)] Using preset height: \(exactHeight)")
            let newSize = NSSize(width: bounds.width, height: exactHeight)
            self.frame = NSRect(origin: .zero, size: newSize)
            self.onSizeChanged?(newSize)
            return
        }

        print("KNA - [\(viewID)] Updating content size")

        Task {
            _ = try? await evaluateJavaScript("""
                document.body.style.overflow = 'hidden';
                document.documentElement.style.overflow = 'hidden';
            """)

            let result = try? await evaluateJavaScript("""
                (function() {
                    const formula = document.getElementById('formula');
                    if (!formula) return null;
                    
                    // Attendre que MathJax ait fini le rendu
                    if (typeof MathJax !== 'undefined') {
                        await MathJax.typesetPromise([formula]);
                    }
                    
                    const formulaRect = formula.getBoundingClientRect();
                    const mathElements = formula.getElementsByClassName('MathJax');
                    
                    let maxHeight = formulaRect.height;
                    let maxWidth = formulaRect.width;
                    
                    // Vérifier aussi la hauteur des éléments MathJax
                    for (const elem of mathElements) {
                        const rect = elem.getBoundingClientRect();
                        maxHeight = Math.max(maxHeight, rect.height);
                        maxWidth = Math.max(maxWidth, rect.width);
                    }
                    
                    // Ajouter une marge minimale pour éviter les coupures
                    maxHeight += 2; // Réduit de 5 à 2
                    maxWidth += 2; // Réduit de 5 à 2
                    
                    // Supprimer les marges et paddings en bas après le rendu
                    document.querySelectorAll('.MathJax, mjx-container, .latex-document, .latex-content, #formula').forEach(el => {
                        el.style.marginBottom = '0';
                        el.style.paddingBottom = '0';
                    });
                    
                    return [maxWidth, maxHeight];
                })()
            """) as? [CGFloat]

            await MainActor.run {
                if let dimensions = result, dimensions.count == 2 {
                    let calculatedWidth = max(dimensions[0], bounds.width)
                    let calculatedHeight = dimensions[1] + extraPadding
                    
                    // Arrondir la hauteur au multiple de 2 supérieur pour éviter les petites fluctuations
                    let roundedHeight = ceil(calculatedHeight / 2.0) * 2.0 // Réduit de 5 à 2
                    
                    // Pas de marge supplémentaire
                    let finalHeight = roundedHeight
                    
                    let newSize = NSSize(
                        width: calculatedWidth,
                        height: max(finalHeight, minHeight)
                    )

                    let oldFrame = self.frame
                    self.frame = NSRect(origin: .zero, size: newSize)

                    print("KNA - [\(viewID)] Content size updated from \(oldFrame.size) to \(newSize), calculatedHeight: \(calculatedHeight), roundedHeight: \(roundedHeight), finalHeight: \(finalHeight)")

                    self.onSizeChanged?(newSize)
                } else {
                    print("KNA - [\(viewID)] Failed to get dimensions from JavaScript")
                    // Utiliser une hauteur par défaut plus petite si le calcul échoue
                    let defaultHeight = max(minHeight, fontSize * 1.5) // Réduit de 2 à 1.5
                    // Arrondir au multiple de 2 supérieur
                    let roundedHeight = ceil(defaultHeight / 2.0) * 2.0 // Réduit de 5 à 2
                    let newSize = NSSize(width: bounds.width, height: roundedHeight)
                    self.frame = NSRect(origin: .zero, size: newSize)
                    self.onSizeChanged?(newSize)
                }
            }
        }
    }
    
    // Méthode pour définir une hauteur exacte
    func presetHeight(_ height: CGFloat) {
        // Arrondir la hauteur au multiple de 2 supérieur pour éviter les petites fluctuations
        let roundedHeight = ceil(height / 2.0) * 2.0 // Réduit de 5 à 2
        
        // Pas de marge supplémentaire
        let finalHeight = roundedHeight
        
        self.exactHeight = finalHeight
        self.heightPreset = true
        print("KNA - [\(viewID)] Preset height to \(height), rounded to \(roundedHeight), final: \(finalHeight)")
        
        // Mettre à jour la taille immédiatement si possible
        if bounds.width > 0 {
            let newSize = NSSize(width: bounds.width, height: finalHeight)
            self.frame = NSRect(origin: .zero, size: newSize)
            self.onSizeChanged?(newSize)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("KNA - [\(viewID)] WebView finished loading")
        updateContentSize()
        
        // Forcer un relayout complet après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if let onSizeChanged = self.onSizeChanged, let exactHeight = self.exactHeight {
                // Notifier à nouveau du changement de taille pour forcer un relayout
                let size = NSSize(width: self.bounds.width, height: exactHeight)
                onSizeChanged(size)
                
                // Forcer la mise à jour de la vue parente
                if let superview = self.superview, let textView = superview.superview as? NSTextView {
                    textView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textView.textStorage?.length ?? 0), actualCharacterRange: nil)
                    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                    textView.needsLayout = true
                    textView.needsDisplay = true
                    
                    // Forcer le recalcul de la taille de la vue parente
                    if let parentView = textView.superview?.superview as? MarkdownLatexTextView {
                        parentView.invalidateIntrinsicContentSize()
                        parentView.layout()
                        parentView.layoutSubtreeIfNeeded()
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("KNA - [\(viewID)] WebView failed to load:", error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("KNA - [\(viewID)] WebView failed provisional navigation:", error)
    }
    
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}

// MARK: - ScriptMessageHandler

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

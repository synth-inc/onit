//
//  MarkdownLatexPreview.swift
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//

import AppKit
import Defaults
import SwiftUI
import WebKit
import os

struct MarkdownLatexPreview: NSViewRepresentable {
    let markdownText: String
    @Binding var webViewHeight: CGFloat
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    @Default(.fontSize) var codeFontSize
    @Default(.lineHeight) var codeLineHeight

    private let logger = Logger(subsystem: "com.onit.MarkdownLatexPreview", category: "WebView")
    
    private let htmlURL: URL? = Bundle.main.url(forResource: "markdownLatex", withExtension: "html")
    private let htmlContent: String? = {
        guard let bundlePath = Bundle.main.path(forResource: "markdownLatex", ofType: "html"),
              let htmlContent = try? String(contentsOfFile: bundlePath, encoding: .utf8) else {
            return nil
        }
        
        return htmlContent
    }()
    private let injectMarkdownRawJS: String? = {
        guard let bundlePath = Bundle.main.path(forResource: "injectMarkdown", ofType: "js"),
              let jsContent = try? String(contentsOfFile: bundlePath, encoding: .utf8) else {
            return nil
        }
        
        return jsContent
    }()
    

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MarkdownLatexPreview

        init(parent: MarkdownLatexPreview) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let escapedMarkdown = self.parent.formatMarkdown()
            
            if let jsCodeRaw = self.parent.injectMarkdownRawJS {
                let jsCode = jsCodeRaw.replacingOccurrences(of: "[TEXT]", with: escapedMarkdown)
                
                webView.evaluateJavaScript(jsCode) { result, error in
                    if let error = error {
                        self.parent.logger.error("Error while rendering markdown: \(error.localizedDescription)")
                    }
                }
                
                // Height check
                webView.evaluateJavaScript("document.body.scrollHeight") { height, error in
                    if let error = error {
                        self.parent.logger.error("Error while computing height: \(error.localizedDescription)")
                    }
                    
                    if let height = height as? CGFloat {
                        DispatchQueue.main.async {
                            self.parent.webViewHeight = height
                        }
                    } else {
                        self.parent.logger.error("Can't get height")
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            self.parent.logger.error("Loading failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.parent.logger.error("Navigation failed: \(error.localizedDescription)")
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightHandler" {
                if let height = message.body as? Double {
                    DispatchQueue.main.async {
                        self.parent.webViewHeight = CGFloat(height)
                    }
                }
            }
            
            if message.name == "logHandler" {
                if let logMessage = message.body as? String {
                    self.parent.logger.debug("Log JS: \(logMessage)")
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeNSView(context: Self.Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "heightHandler")
        userContentController.add(context.coordinator, name: "logHandler")
        
        let cssVariables = """
            const style = document.createElement('style');
            style.textContent = `
                :root {
                    --font-size: \(Int(fontSize))px;
                    --line-height: \(lineHeight);
                    --code-font-size: \(Int(codeFontSize))px;
                    --code-line-height: \(codeLineHeight);
                }
            `;
            document.head.appendChild(style);
        """
        let cssScript = WKUserScript(
            source: cssVariables,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(cssScript)
        configuration.userContentController = userContentController
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences = preferences
        
        let webView = VerticalScrollPassthroughWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.navigationDelegate = context.coordinator
        
        if let htmlContent = htmlContent, let htmlURL = htmlURL {
            webView.loadHTMLString(htmlContent, baseURL: htmlURL.deletingLastPathComponent())
        } else {
            logger.debug("Can't load HTML content")
        }
        
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Self.Context) {
        let cssVariables = """
            const styleElement = document.querySelector('style');
            if (styleElement) {
                styleElement.textContent = `
                    :root {
                        --font-size: \(Int(fontSize))px;
                        --line-height: \(lineHeight);
                        --code-font-size: \(Int(codeFontSize))px;
                        --code-line-height: \(codeLineHeight);
                    }
                `;
            } else {
                const style = document.createElement('style');
                style.textContent = `
                    :root {
                        --font-size: \(Int(fontSize))px;
                        --line-height: \(lineHeight);
                        --code-font-size: \(Int(codeFontSize))px;
                        --code-line-height: \(codeLineHeight);
                    }
                `;
                document.head.appendChild(style);
            }
        """
        webView.evaluateJavaScript(cssVariables)
        
        let escapedMarkdown = formatMarkdown()
        if let jsCodeRaw = self.injectMarkdownRawJS {
            let jsCode = jsCodeRaw.replacingOccurrences(of: "[TEXT]", with: escapedMarkdown)
         
            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    self.logger.error("Error while rendering markdown: \(error.localizedDescription)")
                }
            }
        }
    }

    private func formatMarkdown() -> String {
        var preservedFormulas: [(placeholder: String, formula: String)] = []
        var counter = 0
        
        func createPlaceholder() -> String {
            counter += 1
            return "___LATEX_FORMULA_\(counter)___"
        }
        
        func preserveFormula(_ formula: String) -> String {
            let placeholder = createPlaceholder()
            let processedFormula = formula
                .replacingOccurrences(of: "\\_", with: "_")
                .replacingOccurrences(of: "\\\\", with: "\\\\\\\\")
            
            preservedFormulas.append((placeholder, processedFormula))
            return placeholder
        }
        
        var processedText = markdownText
        
        if let displayPattern = try? NSRegularExpression(pattern: "\\\\\\[([\\s\\S]*?)\\\\\\]") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = displayPattern.matches(in: processedText, range: nsRange)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let formulaRange = Range(match.range(at: 1), in: processedText) {
                    let formula = String(processedText[formulaRange])
                    let placeholder = preserveFormula("\\\\[\(formula)\\\\]")
                    
                    processedText.replaceSubrange(range, with: placeholder)
                }
            }
        }

        if let inlinePattern = try? NSRegularExpression(pattern: "\\\\\\(([\\s\\S]*?)\\\\\\)") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = inlinePattern.matches(in: processedText, range: nsRange)
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let formulaRange = Range(match.range(at: 1), in: processedText) {
                    let formula = String(processedText[formulaRange])
                    let placeholder = preserveFormula("\\\\(\(formula)\\\\)")
                    
                    processedText.replaceSubrange(range, with: placeholder)
                }
            }
        }
        
        var formattedText = processedText
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")

        for (placeholder, formula) in preservedFormulas {
            formattedText = formattedText.replacingOccurrences(of: placeholder, with: formula)
        }
        
        return formattedText
    }
}

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

    // Logger pour le débogage
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
                        self.parent.logger.error("Erreur lors du rendu du markdown: \(error.localizedDescription)")
                    }
                }
                
                // Height check
                webView.evaluateJavaScript("document.body.scrollHeight") { height, error in
                    if let error = error {
                        self.parent.logger.error("Erreur lors de l'évaluation de la hauteur: \(error.localizedDescription)")
                    }
                    
                    if let height = height as? CGFloat {
                        self.parent.logger.debug("Hauteur initiale: \(height)")
                        DispatchQueue.main.async {
                            self.parent.webViewHeight = height
                        }
                    } else {
                        self.parent.logger.error("Impossible d'obtenir la hauteur")
                    }
                }
            }
        }
        
        // Gérer les erreurs de chargement
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            self.parent.logger.error("Échec du chargement: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.parent.logger.error("Échec de la navigation: \(error.localizedDescription)")
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightHandler" {
                if let height = message.body as? CGFloat {
                    self.parent.logger.debug("Nouvelle hauteur reçue: \(height)")
                    DispatchQueue.main.async {
                        self.parent.webViewHeight = height
                    }
                } else {
                    self.parent.logger.error("Type de hauteur invalide: \(type(of: message.body))")
                }
            }
            
            // Ajouter un handler pour les logs JavaScript
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
        logger.debug("makeNSView appelé avec markdownText de longueur: \(markdownText.count)")
        
        // Configure WKWebViewConfiguration
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "heightHandler")
        userContentController.add(context.coordinator, name: "logHandler")
        
        // Injecter les variables CSS
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
        
        // Activer les logs de console JavaScript
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences = preferences
        
        // Create and configure WebView with our custom subclass
        let webView = VerticalScrollPassthroughWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.navigationDelegate = context.coordinator
        
        // Load HTML content
        if let htmlContent = htmlContent, let htmlURL = htmlURL {
            webView.loadHTMLString(htmlContent, baseURL: htmlURL.deletingLastPathComponent())
        } else {
            logger.debug("Can't load HTML content")
        }
        
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Self.Context) {
        logger.debug("updateNSView appelé avec markdownText de longueur: \(markdownText.count)")
        
        // Mettre à jour les variables CSS
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
        
        // Mettre à jour le contenu avec rendu Markdown et LaTeX
        let escapedMarkdown = formatMarkdown()
        if let jsCodeRaw = self.injectMarkdownRawJS {
            let jsCode = jsCodeRaw.replacingOccurrences(of: "[TEXT]", with: escapedMarkdown)
         
            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    self.logger.error("Erreur lors de la mise à jour du markdown: \(error.localizedDescription)")
                } else {
                    self.logger.debug("Markdown mis à jour avec succès")
                }
            }
        }
    }

    private func formatMarkdown() -> String {
        logger.debug("formatMarkdown appelé avec texte de longueur: \(markdownText.count)")
        
        // Log des premiers caractères pour débogage
        if !markdownText.isEmpty {
            let previewText = String(markdownText)
            logger.debug("Markdown: \(previewText)")
        } else {
            logger.error("Le texte markdown est vide!")
        }
        
        // Préserver les formules LaTeX en les remplaçant temporairement
        var preservedFormulas: [(placeholder: String, formula: String)] = []
        var counter = 0
        
        // Fonction pour créer un placeholder unique
        func createPlaceholder() -> String {
            counter += 1
            return "___LATEX_FORMULA_\(counter)___"
        }
        
        // Fonction pour préserver une formule
        func preserveFormula(_ formula: String) -> String {
            let placeholder = createPlaceholder()
            // Prétraiter la formule pour gérer les underscores et autres caractères spéciaux
            let processedFormula = formula
                .replacingOccurrences(of: "\\_", with: "_") // Remplacer \_ par _
                .replacingOccurrences(of: "\\\\", with: "\\\\\\\\") // Doubler les backslashes
            preservedFormulas.append((placeholder, processedFormula))
            return placeholder
        }
        
        // Préserver les formules display et inline
        var processedText = markdownText
        
        // Préserver les formules display \[...\]
        if let displayPattern = try? NSRegularExpression(pattern: "\\\\\\[([\\s\\S]*?)\\\\\\]") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = displayPattern.matches(in: processedText, range: nsRange)
            
            // Traiter les matches en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let formulaRange = Range(match.range(at: 1), in: processedText) {
                    let formula = String(processedText[formulaRange])
                    let placeholder = preserveFormula("\\\\[\(formula)\\\\]")
                    processedText.replaceSubrange(range, with: placeholder)
                }
            }
        }
            
        // Préserver les formules inline \(...\)
        if let inlinePattern = try? NSRegularExpression(pattern: "\\\\\\(([\\s\\S]*?)\\\\\\)") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = inlinePattern.matches(in: processedText, range: nsRange)
            
            // Traiter les matches en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let formulaRange = Range(match.range(at: 1), in: processedText) {
                    let formula = String(processedText[formulaRange])
                    let placeholder = preserveFormula("\\\\(\(formula)\\\\)")
                    processedText.replaceSubrange(range, with: placeholder)
                }
            }
        }
        
        // Échapper les caractères spéciaux pour JavaScript
        var formattedText = processedText
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            
        // Restaurer les formules LaTeX
        for (placeholder, formula) in preservedFormulas {
            formattedText = formattedText.replacingOccurrences(of: placeholder, with: formula)
        }
        
        logger.debug("Texte formaté: \(formattedText)")
        logger.debug("Texte formaté de longueur: \(formattedText.count)")
        return formattedText
    }
}

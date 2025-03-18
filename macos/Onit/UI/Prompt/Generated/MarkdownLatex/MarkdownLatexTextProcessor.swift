//
//  MarkdownLatexTextProcessor.swift
//  Onit
//
//  Created by Kévin Naudin on 17/03/2025.
//

import AppKit

struct MarkdownLatexTextProcessor {
    
    func process(_ markdown: String) -> String {
        print("🔵 formatMarkdown - Starting markdown formatting")
        print("📝 Input text: \(markdown)")
        
        // Supprimer les délimiteurs de blocs LaTeX
        var processedText = removeLatexBlockQuotes(markdown)
        
        // Prétraiter les documents LaTeX pour gérer les environnements problématiques
        processedText = preprocessLatexDocuments(processedText)
        
        let latexDocuments = extractFullLatexDocument(&processedText)
        let preservedFormulas = extractMathFormulas(&processedText)
        
        print("📝 Text after extraction: \(processedText)")
        
        // Étape 3: Échapper les caractères spéciaux pour JavaScript
        var formattedText = processedText
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            
        print("📝 Text after escaping: \(formattedText)")

        // Étape 4: Restaurer les formules mathématiques
        for (placeholder, formula) in preservedFormulas {
            print("🔄 Restoring formula: '\(formula)' for placeholder: '\(placeholder)'")
            formattedText = formattedText.replacingOccurrences(of: placeholder, with: formula)
        }
        
        // Étape 5: Restaurer les documents LaTeX complets
        for (placeholder, latexDocument) in latexDocuments {
            // Échapper uniquement les caractères nécessaires pour JavaScript
            let escapedLatex = latexDocument
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            
            print("🔄 Restoring LaTeX document for placeholder: '\(placeholder)'")
            formattedText = formattedText.replacingOccurrences(of: placeholder, with: escapedLatex)
        }
        
        print("✅ Final formatted text: \(formattedText)")
        return formattedText
    }
    
    private func removeLatexBlockQuotes(_ text: String) -> String {
        print("🔍 Removing LaTeX block quotes")
        var processedText = text
        
        // Regex pour trouver les blocs de code LaTeX: ```latex ... ``` avec espaces possibles devant
        if let latexBlockPattern = try? NSRegularExpression(pattern: "[ \\t]*```latex\\s*\\n([\\s\\S]*?)\\n[ \\t]*```") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = latexBlockPattern.matches(in: processedText, range: nsRange)
            
            print("📊 Found \(matches.count) LaTeX block quotes")
            
            // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let contentRange = Range(match.range(at: 1), in: processedText) {
                    let blockContent = String(processedText[contentRange])
                    print("🔄 Extracting content from LaTeX block: \(blockContent.prefix(50))\(blockContent.count > 50 ? "..." : "")")
                    
                    // Remplacer le bloc entier par son contenu uniquement
                    processedText.replaceSubrange(range, with: blockContent)
                }
            }
        }
        
        if let latexBlockPattern = try? NSRegularExpression(pattern: "[ \\t]*```\\s*\\n([\\s\\S]*?)\\n[ \\t]*```") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = latexBlockPattern.matches(in: processedText, range: nsRange)
            
            print("📊 Found \(matches.count) empty block quotes")
            
            // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let contentRange = Range(match.range(at: 1), in: processedText) {
                    let blockContent = String(processedText[contentRange])
                    print("🔄 Extracting content from empty block: \(blockContent.prefix(50))\(blockContent.count > 50 ? "..." : "")")
                    
                    // Remplacer le bloc entier par son contenu uniquement
                    processedText.replaceSubrange(range, with: blockContent)
                }
            }
        }
        
        return processedText
    }
    
    private func extractFullLatexDocument(_ text: inout String) -> [(placeholder: String, content: String)] {
        // Étape 1: Extraire les documents LaTeX complets
        var latexDocuments: [(placeholder: String, content: String)] = []
        var latexCounter = 0
        
        // Regex pour extraire les documents LaTeX complets (de \documentclass à \end{document})
        let fullLatexPattern = try? NSRegularExpression(pattern: "(\\\\documentclass[\\s\\S]*?\\\\end\\{document\\})")
        
        if let pattern = fullLatexPattern {
            print("🔍 Searching for full LaTeX documents")
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = pattern.matches(in: text, range: nsRange)
            
            print("📊 Found \(matches.count) LaTeX documents")
            
            // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let latexDocument = String(text[range])
                    latexCounter += 1
                    let placeholder = "___LATEX_DOCUMENT_\(latexCounter)___"
                    
                    print("🔄 Extracting LaTeX document \(latexCounter)")
                    latexDocuments.append((placeholder, latexDocument))
                    
                    // Remplacer le document LaTeX par un placeholder
                    text.replaceSubrange(range, with: placeholder)
                }
            }
        }
        
        return latexDocuments
    }
    
    private func extractMathFormulas(_ text: inout String) -> [(placeholder: String, formula: String)] {
        // Étape 2: Traitement normal des formules mathématiques dans le texte restant
        var preservedFormulas: [(placeholder: String, formula: String)] = []
        var counter = 0
        
        func preserveFormula(_ formula: String) -> String {
            let placeholder = "___LATEX_FORMULA_\(counter + 1)___"
            counter += 1
            let processedFormula = formula
                .replacingOccurrences(of: "\\_", with: "_")
                .replacingOccurrences(of: "\\\\", with: "\\\\\\\\")
            
            print("🔢 Formula \(counter): '\(formula)' -> '\(processedFormula)'")
            preservedFormulas.append((placeholder, processedFormula))
            return placeholder
        }
        
        // Display math pattern (\[ ... \]) avec espaces possibles devant
        if let displayPattern = try? NSRegularExpression(pattern: "[ \\t]*\\\\\\[([\\s\\S]*?)\\\\\\]") {
            print("🔍 Searching for display math patterns")
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = displayPattern.matches(in: text, range: nsRange)
            
            print("📊 Found \(matches.count) display math patterns")
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let formulaRange = Range(match.range(at: 1), in: text) {
                    let formula = String(text[formulaRange])
                    let placeholder = preserveFormula("\\\\[\(formula)\\\\]")
                    print("🔄 Replacing display math: '\(formula)' with placeholder: '\(placeholder)'")
                    text.replaceSubrange(range, with: placeholder)
                }
            }
        }

        // Inline math pattern (\( ... \)) avec espaces possibles devant
        if let inlinePattern = try? NSRegularExpression(pattern: "[ \\t]*\\\\\\(([\\s\\S]*?)\\\\\\)") {
            print("🔍 Searching for inline math patterns")
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = inlinePattern.matches(in: text, range: nsRange)
            
            print("📊 Found \(matches.count) inline math patterns")
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let formulaRange = Range(match.range(at: 1), in: text) {
                    let formula = String(text[formulaRange])
                    let placeholder = preserveFormula("\\\\(\(formula)\\\\)")
                    print("🔄 Replacing inline math: '\(formula)' with placeholder: '\(placeholder)'")
                    text.replaceSubrange(range, with: placeholder)
                }
            }
        }
        
        return preservedFormulas
    }
    
    private func preprocessLatexDocuments(_ text: String) -> String {
        print("🔄 Preprocessing LaTeX documents to handle problematic environments")
        var processedText = text
        
        // Regex pour trouver les documents LaTeX complets
        if let latexDocPattern = try? NSRegularExpression(pattern: "(\\\\documentclass[\\s\\S]*?\\\\end\\{document\\})") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = latexDocPattern.matches(in: processedText, range: nsRange)
            
            print("📊 Found \(matches.count) LaTeX documents to preprocess")
            
            // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText) {
                    let latexDocument = String(processedText[range])
                    
                    // Prétraiter le document LaTeX
                    var processedDoc = latexDocument
                    
                    // Traiter les environnements d'équation
                    processedDoc = convertEquationEnvironments(processedDoc)
                    
                    // Traiter les environnements problématiques
                    processedDoc = convertProblematicEnvironments(processedDoc)
                    
                    // Remplacer les commandes non supportées
                    processedDoc = replaceUnsupportedCommands(processedDoc)
                    
                    // Remplacer le document original par le document prétraité
                    processedText.replaceSubrange(range, with: processedDoc)
                }
            }
        }
        
        return processedText
    }
    
    private func convertEquationEnvironments(_ text: String) -> String {
        var processedText = text
        
        // Liste des environnements d'équation à convertir
        let mathEnvironments = ["equation", "align", "gather", "multline", "eqnarray", "displaymath"]
        
        for env in mathEnvironments {
            if let pattern = try? NSRegularExpression(pattern: "[ \\t]*\\\\begin\\{\(env)\\}([\\s\\S]*?)[ \\t]*\\\\end\\{\(env)\\}") {
                print("🔍 Converting \(env) environments to display math notation")
                let nsRange = NSRange(processedText.startIndex..., in: processedText)
                let matches = pattern.matches(in: processedText, range: nsRange)
                
                print("📊 Found \(matches.count) \(env) environments")
                
                // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: processedText),
                       let contentRange = Range(match.range(at: 1), in: processedText) {
                        let content = String(processedText[contentRange])
                        print("🔄 Converting \(env): \(content.prefix(50))\(content.count > 50 ? "..." : "")")
                        
                        // Remplacer par la notation \[...\]
                        let replacement = "\\[\(content)\\]"
                        processedText.replaceSubrange(range, with: replacement)
                    }
                }
            }
        }
        
        return processedText
    }
    
    private func convertProblematicEnvironments(_ text: String) -> String {
        var processedText = text
        
        // Liste des environnements problématiques
        let problematicEnvironments = ["center", "proof", "theorem"]
        
        for env in problematicEnvironments {
            if let pattern = try? NSRegularExpression(pattern: "[ \\t]*\\\\begin\\{\(env)\\}([\\s\\S]*?)[ \\t]*\\\\end\\{\(env)\\}") {
                print("🔍 Converting \(env) environments")
                let nsRange = NSRange(processedText.startIndex..., in: processedText)
                let matches = pattern.matches(in: processedText, range: nsRange)
                
                print("📊 Found \(matches.count) \(env) environments")
                
                // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: processedText),
                       let contentRange = Range(match.range(at: 1), in: processedText) {
                        let content = String(processedText[contentRange])
                        print("🔄 Converting \(env): \(content.prefix(50))\(content.count > 50 ? "..." : "")")
                        
                        // Pour tabular et array, on préserve juste le contenu
                        let replacement: String
                        if ["tabular", "tabularx", "array", "longtable"].contains(env) {
                            replacement = content
                        } else if env == "center" {
                            // Pour center, on garde juste le contenu
                            replacement = content
                        } else if env == "theorem" {
                            replacement = "\\textbf{Theorem.} \(content)"
                        } else if env == "proof" {
                            replacement = "\\textbf{Proof.} \(content)"
                        } else {
                            // Pour les autres, on garde juste le contenu
                            replacement = content
                        }
                        
                        processedText.replaceSubrange(range, with: replacement)
                    }
                }
            }
        }
        
        return processedText
    }
    
    private func replaceUnsupportedCommands(_ text: String) -> String {
        var processedText = text
        
        // Dictionnaire des commandes à remplacer
        let commandReplacements: [(pattern: String, replacement: String)] = [
            ("\\\\toprule", "\\\\hline\\\\hline"),
            ("\\\\midrule", "\\\\hline"),
            ("\\\\bottomrule", "\\\\hline\\\\hline"),
            ("\\\\cmidrule(\\{[^}]*\\})*", "\\\\hline"),
            ("\\\\multicolumn(\\{[^}]*\\})*", ""),
            // Ne pas remplacer includegraphics car nous le traitons spécifiquement dans injectMarkdown.js
            // ("\\\\includegraphics(\\{[^}]*\\})*", "\\\\textbf{[Image]}"),
            ("\\\\caption(\\{[^}]*\\})*", "\\\\textbf{Caption:}"),
            ("\\\\label(\\{[^}]*\\})*", ""),
            ("\\\\ref(\\{[^}]*\\})*", "??"),
            ("\\\\cite(\\{[^}]*\\})*", "[citation]"),
            ("\\\\footnote(\\{[^}]*\\})*", "[note]"),
            ("\\\\printbibliography", "\\\\textbf{Bibliographie}"),
            ("\\\\definecolor(\\{[^}]*\\})*", ""),
            ("\\\\lstset(\\{[^}]*\\})*", "")
        ]
        
        print("🔍 Replacing unsupported LaTeX commands")
        
        for (pattern, replacement) in commandReplacements {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(processedText.startIndex..., in: processedText)
                let matches = regex.matches(in: processedText, range: nsRange)
                
                print("📊 Found \(matches.count) occurrences of \(pattern)")
                
                // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: processedText) {
                        print("🔄 Replacing \(processedText[range]) with \(replacement)")
                        processedText.replaceSubrange(range, with: replacement)
                    }
                }
            }
        }
        
        // Traiter l'environnement lstlisting
        if let lstlistingPattern = try? NSRegularExpression(pattern: "\\\\begin\\{lstlisting\\}(\\[.*?\\])?(([\\s\\S]*?)\\\\end\\{lstlisting\\})") {
            let nsRange = NSRange(processedText.startIndex..., in: processedText)
            let matches = lstlistingPattern.matches(in: processedText, range: nsRange)
            
            print("📊 Found \(matches.count) lstlisting environments")
            
            // Traiter les correspondances en commençant par la fin pour ne pas perturber les indices
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText),
                   let optionsRange = Range(match.range(at: 1), in: processedText),
                   let contentRange = Range(match.range(at: 3), in: processedText) {
                    
                    let options = String(processedText[optionsRange])
                    let codeContent = String(processedText[contentRange])
                    
                    print("🔄 Converting lstlisting environment to code block")
                    
                    // Extraire la légende si elle existe
                    var caption = ""
                    if options.contains("caption=") {
                        if let captionPattern = try? NSRegularExpression(pattern: "caption=\\{([^}]*)\\}"),
                           let captionMatch = captionPattern.firstMatch(in: options, range: NSRange(options.startIndex..., in: options)),
                           let captionContentRange = Range(captionMatch.range(at: 1), in: options) {
                            let captionText = String(options[captionContentRange])
                            caption = "\\\\textbf{Listing:} \(captionText)"
                        }
                    }
                    
                    let replacement = "\(caption)\n\\\\begin{verbatim}\(codeContent)\\\\end{verbatim}"
                    processedText.replaceSubrange(range, with: replacement)
                }
            }
        }
        
        return processedText
    }
}

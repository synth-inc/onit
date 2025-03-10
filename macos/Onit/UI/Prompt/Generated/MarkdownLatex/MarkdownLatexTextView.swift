//
//  MarkdownLatexTextView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import AppKit
import Highlightr
import SwiftUI

class MarkdownLatexTextView: NSView {
    // UI Components
    private let textView: NSTextView
    @MainActor private let parser: MarkdownLatexParser
    
    // Text configuration
    private let fontSize: CGFloat
    private let lineHeight: CGFloat
    
    // Customizable appearance properties
    var textContainerInsets: NSEdgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    var defaultLineSpacing: CGFloat = 1.2 // Multiplier for fontSize
    var defaultParagraphSpacing: CGFloat = 0.3 // Réduit de 0.4 à 0.3
    var codeBlockSpacing: CGFloat = 0.6 // Réduit de 0.8 à 0.6
    var latexBlockSpacing: CGFloat = 0.2 // Réduit de 0.3 à 0.2
    
    // Code block configuration
    var codeBlockTitleBarHeight: CGFloat = 24
    var codeBlockDividerHeight: CGFloat = 1
    var codeBlockCornerRadius: CGFloat = 10
    var codeBlockBorderWidth: CGFloat = 1
    var codeBlockPadding: CGFloat = 10 // Réduit de 12 à 10
    var codeBlockExtraBuffer: CGFloat = 10 // Extra buffer to prevent overlap
    
    // LaTeX configuration
    var latexMinHeight: CGFloat = 0 // Sera initialisée dans init
    var latexExtraPadding: CGFloat = 2 // Réduit de 5 à 2
    var latexVerticalMargin: CGFloat = 0 // Déjà à 0
    
    init(text: String, fontSize: CGFloat, lineHeight: CGFloat) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.latexMinHeight = fontSize * 1.2 // Réduit de 1.5 à 1.2
        
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
        textView.textContainerInset = NSSize(width: textContainerInsets.left, height: textContainerInsets.top)
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
            print("KNA - Setting text with length: \(text.count)")
            let elements = await parser.parse(text)
            print("KNA - Parsed \(elements.count) elements")
            
            let attributedString = NSMutableAttributedString()
            
            let defaultParagraphStyle = NSMutableParagraphStyle()
            defaultParagraphStyle.lineSpacing = (lineHeight * fontSize) - fontSize
            defaultParagraphStyle.paragraphSpacing = defaultParagraphSpacing * fontSize
            
            // Fonction auxiliaire pour vérifier si un élément est un bloc de code
            func isCodeElement(_ element: MarkdownLatexParser.Element) -> Bool {
                if case .code(_, _, _) = element {
                    return true
                }
                return false
            }
            
            // Fonction auxiliaire pour vérifier si un élément est un bloc LaTeX
            func isLatexElement(_ element: MarkdownLatexParser.Element) -> Bool {
                if case .latex(_, _) = element {
                    return true
                }
                return false
            }
            
            for (index, element) in elements.enumerated() {
                // Ajouter un espacement supplémentaire avant les blocs de code ou LaTeX si nécessaire
                let needsExtraSpaceBefore = index > 0 && 
                                          (isCodeElement(element) || isLatexElement(element)) && 
                                          !isCodeElement(elements[index-1]) && 
                                          !isLatexElement(elements[index-1])
                
                if needsExtraSpaceBefore {
                    // Ajouter un petit espace avant les blocs spéciaux
                    let spaceAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: fontSize * 0.5), // Réduire la taille pour un espacement plus petit
                        .foregroundColor: NSColor.white
                    ]
                    attributedString.append(NSAttributedString(string: "\n", attributes: spaceAttrs))
                }
                
                switch element {
                case .text(let str):
                    print("KNA - Processing text element [\(index)] with length: \(str.count)")
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: fontSize),
                        .foregroundColor: NSColor.white,
                        .paragraphStyle: defaultParagraphStyle
                    ]
                    attributedString.append(NSAttributedString(string: str, attributes: attrs))
                    
                case .code(let code, let language, let isGenerating):
                    print("KNA - Processing code element [\(index)] with length: \(code.count), language: \(language ?? "unknown")")
                    if isGenerating {
                        let generatingText = "Generating..."
                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: NSFont.systemFont(ofSize: fontSize),
                            .foregroundColor: NSColor.gray,
                            .paragraphStyle: defaultParagraphStyle
                        ]
                        attributedString.append(NSAttributedString(string: generatingText, attributes: attrs))
                    } else {
                        let codeBlock = createCodeBlock(code: code, language: language)
                        attributedString.append(codeBlock)
                    }
                    
                case .latex(let latex, let isGenerating):
                    print("KNA - Processing latex element [\(index)] with length: \(latex.count)")
                    
                    if isGenerating {
                        let generatingText = "Generating..."
                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: NSFont.systemFont(ofSize: fontSize),
                            .foregroundColor: NSColor.gray,
                            .paragraphStyle: defaultParagraphStyle
                        ]
                        attributedString.append(NSAttributedString(string: generatingText, attributes: attrs))
                    } else {
                        let latexBlock = createLatexView(latex: latex)
                        attributedString.append(latexBlock)
                    }
                }
                
                // Ajouter un espacement supplémentaire après les blocs de code ou LaTeX si nécessaire
                let needsExtraSpaceAfter = index < elements.count - 1 && 
                                         (isCodeElement(element) && !isCodeElement(elements[index+1]) && !isLatexElement(elements[index+1]))
                                         // Ne pas ajouter d'espace après les éléments LaTeX car ils ont déjà un saut de ligne
                
                if needsExtraSpaceAfter {
                    // Ajouter un petit espace après les blocs spéciaux
                    let spaceAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: fontSize * 0.5), // Réduire la taille pour un espacement plus petit
                        .foregroundColor: NSColor.white
                    ]
                    attributedString.append(NSAttributedString(string: "\n", attributes: spaceAttrs))
                }
            }
            
            print("KNA - Setting attributed string with length: \(attributedString.length)")
            self.textView.textStorage?.setAttributedString(attributedString)
            
            self.textView.layoutManager?.ensureLayout(for: self.textView.textContainer!)
            self.textView.layoutManager?.glyphRange(for: self.textView.textContainer!)
            
            if let layoutManager = self.textView.layoutManager {
                let usedRect = layoutManager.usedRect(for: self.textView.textContainer!)
                let newHeight = ceil(usedRect.height + self.textContainerInsets.top + self.textContainerInsets.bottom)
                print("KNA - Calculated view height: \(newHeight)")
                self.frame = NSRect(x: 0, y: 0, width: bounds.width, height: newHeight)
                self.textView.frame = bounds
            }
            
            self.invalidateIntrinsicContentSize()
            
            // Forcer un relayout complet après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                
                // Forcer la mise à jour du layout
                self.textView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: self.textView.textStorage?.length ?? 0), actualCharacterRange: nil)
                self.textView.layoutManager?.ensureLayout(for: self.textView.textContainer!)
                
                // Recalculer la taille
                if let layoutManager = self.textView.layoutManager {
                    let usedRect = layoutManager.usedRect(for: self.textView.textContainer!)
                    let newHeight = ceil(usedRect.height + self.textContainerInsets.top + self.textContainerInsets.bottom)
                    print("KNA - Recalculated view height after delay: \(newHeight)")
                    self.frame = NSRect(x: 0, y: 0, width: self.bounds.width, height: newHeight)
                    self.textView.frame = self.bounds
                }
                
                self.invalidateIntrinsicContentSize()
                self.layout()
                self.layoutSubtreeIfNeeded()
                self.textView.needsLayout = true
                self.textView.needsDisplay = true
            }
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
        print("KNA - Creating code block for language: \(language ?? "unknown")")
        
        // Setup paragraph style for code
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        
        // Attempt syntax highlighting
        var highlightedCode: NSAttributedString
        
        let highlighter = Highlightr()
        highlighter?.setTheme(to: "monokai")
        
        if let highlighted = highlighter?.highlight(code, as: language ?? "swift") {
            // Create mutable copy to modify attributes
            let mutable = NSMutableAttributedString(attributedString: highlighted)
            
            // Apply our custom attributes while preserving syntax colors
            mutable.enumerateAttributes(in: NSRange(location: 0, length: mutable.length), options: []) { attrs, range, _ in
                var newAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont(name: "SometypeMono-Regular", size: fontSize - 1) ?? NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular),
                    .paragraphStyle: paragraphStyle
                ]
                
                // Preserve the syntax highlighting color if it exists
                if let color = attrs[.foregroundColor] as? NSColor {
                    newAttrs[.foregroundColor] = color
                } else {
                    newAttrs[.foregroundColor] = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
                }
                
                mutable.setAttributes(newAttrs, range: range)
            }
            highlightedCode = mutable
        } else {
            // Fallback if highlighting fails
            highlightedCode = NSAttributedString(string: code, attributes: [
                .font: NSFont(name: "SometypeMono-Regular", size: fontSize - 1) ?? NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ])
        }
        
        // IMPORTANT: Accurately calculate the height of the code content
        // Create a temporary text storage and layout manager to calculate the exact height
        let textStorage = NSTextStorage(attributedString: highlightedCode)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: bounds.width - 32, height: .greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Force layout to ensure accurate height calculation
        layoutManager.ensureLayout(for: textContainer)
        let codeHeight = layoutManager.usedRect(for: textContainer).height
        
        // Add padding for title bar and container padding
        let totalHeight = codeHeight + codeBlockTitleBarHeight + codeBlockDividerHeight + codeBlockPadding
        
        // Add extra buffer to ensure no overlap
        let finalHeight = ceil(totalHeight) + codeBlockExtraBuffer
        
        // Create code block view with pre-calculated height
        let codeBlockView = CodeBlockView(code: highlightedCode, language: language)
        
        // Configure the code block view with our custom properties
        codeBlockView.titleBarHeight = codeBlockTitleBarHeight
        codeBlockView.dividerHeight = codeBlockDividerHeight
        codeBlockView.cornerRadius = codeBlockCornerRadius
        codeBlockView.borderWidth = codeBlockBorderWidth
        codeBlockView.textContainerInsets = NSEdgeInsets(
            top: codeBlockPadding / 2,
            left: 10,
            bottom: codeBlockPadding / 2,
            right: 10
        )
        
        // Set the frame for the code block view
        codeBlockView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: finalHeight)
        
        // Pre-set the height constraint to avoid recalculation
        if let heightConstraint = codeBlockView.codeContainerHeightConstraint {
            heightConstraint.constant = codeHeight + codeBlockPadding
        }
        
        // Use the new presetHeight method
        codeBlockView.presetHeight(codeHeight + codeBlockPadding)
        
        // Create attachment with our custom cell
        let attachment = NSTextAttachment()
        let cell = CodeBlockAttachmentCell(codeBlockView: codeBlockView)
        cell.setExactHeight(finalHeight)
        attachment.attachmentCell = cell
        
        // Create the final attributed string with the attachment
        let attachmentString = NSMutableAttributedString(string: "\u{fffc}")
        attachmentString.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))
        
        // Create paragraph style for the attachment with reduced spacing
        let attachmentParagraphStyle = NSMutableParagraphStyle()
        attachmentParagraphStyle.paragraphSpacingBefore = 0
        attachmentParagraphStyle.paragraphSpacing = 0
        attachmentParagraphStyle.alignment = .left
        
        // Apply the paragraph style to the attachment
        attachmentString.addAttribute(.paragraphStyle, value: attachmentParagraphStyle, range: NSRange(location: 0, length: attachmentString.length))
        
        return attachmentString
    }
    
    private func createLatexView(latex: String) -> NSAttributedString {
        print("KNA - Creating LaTeX view for content length: \(latex.count)")
        
        // Utiliser une formule plus précise basée sur le contenu
        let lineCount = latex.components(separatedBy: .newlines).count
        let complexityFactor = calculateLatexComplexity(latex)
        
        // Hauteur de base réduite davantage
        let baseHeight = max(latexMinHeight, fontSize * 1.5) // Réduit de 2 à 1.5
        
        // Ajuster la hauteur en fonction de la complexité et du nombre de lignes
        // Réduire encore plus les facteurs multiplicatifs
        let estimatedHeight = baseHeight + CGFloat(lineCount) * fontSize * 0.3 + complexityFactor * 0.2 // Réduit de 0.5 à 0.3 et de 0.3 à 0.2
        
        // Ajouter un tampon minimal
        // Arrondir au multiple de 2 supérieur pour éviter les fluctuations
        let roundedHeight = ceil((estimatedHeight + latexExtraPadding) / 2.0) * 2.0 // Réduit de 5 à 2
        
        // Pas de marge supplémentaire
        let finalHeight = roundedHeight
        
        print("KNA - Estimated LaTeX height: \(estimatedHeight), rounded height: \(roundedHeight), final height: \(finalHeight), complexity: \(complexityFactor), lines: \(lineCount)")
        
        // Créer l'attachement
        let attachment = NSTextAttachment()
        let cell = LatexAttachmentCell(latex: latex, fontSize: fontSize)
        
        // Configurer la vue LaTeX avec nos propriétés
        if let latexView = cell.getLatexView() {
            latexView.minHeight = latexMinHeight
            latexView.extraPadding = 2 // Réduit de 5 à 2
        }
        
        // Définir la hauteur exacte
        cell.setExactHeight(finalHeight)
        
        // Configurer la marge verticale - réduire pour un meilleur positionnement
        cell.verticalMargin = 0
        
        attachment.attachmentCell = cell
        
        // Créer un style de paragraphe pour l'attachement avec un espacement approprié
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = fontSize * 0.2 // Réduit de 0.3 à 0.2
        paragraphStyle.paragraphSpacing = fontSize * 0.5 // Réduit de 0.8 à 0.5
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 0
        
        // Créer l'attributedString avec l'attachement et le style de paragraphe
        let attachmentString = NSMutableAttributedString(string: "\u{fffc}")
        attachmentString.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))
        attachmentString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: 1))
        
        // Ajouter un saut de ligne explicite après l'attachement
        attachmentString.append(NSAttributedString(string: "\n"))
        
        print("KNA - Created LaTeX attachment with height: \(finalHeight)")
        
        return attachmentString
    }
    
    // Fonction pour calculer la complexité du LaTeX
    private func calculateLatexComplexity(_ latex: String) -> CGFloat {
        var complexity: CGFloat = 0
        
        // Vérifier les structures complexes
        if latex.contains("\\begin{array}") || latex.contains("\\end{array}") {
            complexity += 15 // Réduit de 25 à 15
        }
        
        if latex.contains("\\begin{tabular}") || latex.contains("\\end{tabular}") {
            complexity += 20 // Réduit de 30 à 20
        }
        
        if latex.contains("\\begin{enumerate}") || latex.contains("\\end{enumerate}") {
            complexity += 10 // Réduit de 20 à 10
        }
        
        if latex.contains("\\begin{itemize}") || latex.contains("\\end{itemize}") {
            complexity += 10 // Réduit de 20 à 10
        }
        
        // Vérifier les formules mathématiques
        let mathSymbols = ["\\frac", "\\sum", "\\int", "\\prod", "\\lim", "\\infty", "\\sqrt"]
        for symbol in mathSymbols {
            if latex.contains(symbol) {
                complexity += 5 // Réduit de 8 à 5
            }
        }
        
        // Vérifier les matrices
        if latex.contains("\\begin{matrix}") || latex.contains("\\end{matrix}") {
            complexity += 20 // Réduit de 35 à 20
        }
        
        // Vérifier les environnements d'équation
        if latex.contains("\\begin{equation}") || latex.contains("\\end{equation}") {
            complexity += 10 // Réduit de 15 à 10
        }
        
        // Vérifier les accolades et les crochets (souvent utilisés pour les structures complexes)
        let bracketCount = latex.filter { $0 == "{" || $0 == "}" || $0 == "[" || $0 == "]" }.count
        complexity += CGFloat(bracketCount) * 0.5 // Réduit de 1 à 0.5
        
        // Vérifier la longueur du texte
        complexity += CGFloat(latex.count) / 20 // Réduit de 10 à 20
        
        return complexity
    }
    
    override func layout() {
        super.layout()
        textView.textContainer?.size = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
    }
}

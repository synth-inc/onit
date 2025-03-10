//
//  LaTeXAttachmentCell.swift
//  Onit
//
//  Created by Kévin Naudin on 09/03/2025.
//

import AppKit

class LatexAttachmentCell: NSTextAttachmentCell {
    private let latex: String
    private let fontSize: CGFloat
    private let cellID = UUID().uuidString.prefix(6)
    
    // Propriétés configurables
    private var exactHeight: CGFloat?
    private var lastFrame: NSRect = .zero
    var verticalMargin: CGFloat = 4
    
    // Utiliser une propriété non-lazy pour éviter les problèmes d'isolation du Main actor
    private var latexView: LatexView!
    private var currentSize = NSSize(width: 200, height: 100)
    private weak var control: NSView?
    
    init(latex: String, fontSize: CGFloat) {
        self.latex = latex
        self.fontSize = fontSize
        super.init()
        
        // Ajuster la marge verticale en fonction de la taille de police
        self.verticalMargin = max(1, fontSize * 0.1)
        
        // Initialiser la vue LaTeX après super.init()
        setupLatexView()
        
        print("KNA - Created LaTeXAttachmentCell [\(cellID)] with latex: \(latex.prefix(30))...")
        
        // Définir une hauteur initiale plus petite pour éviter les problèmes de rendu
        self.exactHeight = max(fontSize * 1.5, 30)
    }
    
    private func setupLatexView() {
        self.latexView = LatexView(latex: latex, fontSize: fontSize) { [weak self] newSize in
            guard let self = self else { return }
            
            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Size changed to: \(newSize)")
            
            // Mettre à jour la hauteur exacte avec la nouvelle hauteur calculée
            let newHeight = newSize.height + self.verticalMargin * 2
            
            // Vérifier si la hauteur a réellement changé pour éviter les mises à jour inutiles
            let heightChanged = self.exactHeight != newHeight
            self.exactHeight = newHeight
            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Updated exact height to: \(newHeight)")
            
            self.currentSize = NSSize(width: newSize.width, height: newHeight)
            
            // Seulement invalider le layout si la hauteur a changé
            if heightChanged, let textView = self.control?.enclosingScrollView?.documentView as? NSTextView {
                // Utiliser une approche plus directe pour invalider le layout
                DispatchQueue.main.async {
                    // Trouver l'attachement dans le texte
                    if let textStorage = textView.textStorage {
                        let fullRange = NSRange(location: 0, length: textStorage.length)
                        var attachmentRange: NSRange?
                        
                        textStorage.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, stop in
                            if let attachment = value as? NSTextAttachment,
                               let cell = attachment.attachmentCell as? LatexAttachmentCell,
                               cell === self {
                                attachmentRange = range
                                stop.pointee = true
                            }
                        }
                        
                        if let range = attachmentRange {
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Found attachment at range: \(range)")
                            
                            // Forcer une mise à jour complète du layout
                            textView.layoutManager?.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
                            textView.layoutManager?.invalidateDisplay(forCharacterRange: range)
                            
                            // Forcer le recalcul des glyphes
                            textView.layoutManager?.invalidateGlyphs(forCharacterRange: range, changeInLength: 0, actualCharacterRange: nil)
                            
                            // Forcer le layout complet
                            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                            textView.needsLayout = true
                            textView.needsDisplay = true
                            self.control?.needsDisplay = true
                            
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Invalidated layout for specific attachment")
                        } else {
                            // Fallback à l'invalidation complète
                            textView.layoutManager?.invalidateLayout(forCharacterRange: fullRange, actualCharacterRange: nil)
                            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                            textView.needsLayout = true
                            textView.needsDisplay = true
                            self.control?.needsDisplay = true
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Invalidated layout for entire text")
                        }
                    }
                }
            }
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Méthode pour définir une hauteur exacte
    func setExactHeight(_ height: CGFloat) {
        // Vérifier si la hauteur a réellement changé
        let heightChanged = self.exactHeight != height
        self.exactHeight = height
        print("KNA - LaTeXAttachmentCell [\(cellID)] Set exact height to: \(height)")
        
        // Prérégler la hauteur dans la vue LaTeX
        latexView.presetHeight(height)
        
        // Mettre à jour le cadre de la vue LaTeX si elle est déjà affichée
        if latexView.superview != nil && heightChanged {
            // Mettre à jour le cadre avec la nouvelle hauteur
            var newFrame = latexView.frame
            newFrame.size.height = height
            latexView.frame = newFrame
            
            // Invalider le layout du conteneur de texte si nécessaire
            if heightChanged, let textView = self.control?.enclosingScrollView?.documentView as? NSTextView {
                DispatchQueue.main.async {
                    // Trouver l'attachement dans le texte
                    if let textStorage = textView.textStorage {
                        let fullRange = NSRange(location: 0, length: textStorage.length)
                        var attachmentRange: NSRange?
                        
                        textStorage.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, stop in
                            if let attachment = value as? NSTextAttachment,
                               let cell = attachment.attachmentCell as? LatexAttachmentCell,
                               cell === self {
                                attachmentRange = range
                                stop.pointee = true
                            }
                        }
                        
                        if let range = attachmentRange {
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Found attachment at range: \(range)")
                            
                            // Forcer une mise à jour complète du layout
                            textView.layoutManager?.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
                            textView.layoutManager?.invalidateDisplay(forCharacterRange: range)
                            
                            // Forcer le recalcul des glyphes
                            textView.layoutManager?.invalidateGlyphs(forCharacterRange: range, changeInLength: 0, actualCharacterRange: nil)
                            
                            // Forcer le layout complet
                            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                            textView.needsLayout = true
                            textView.needsDisplay = true
                            self.control?.needsDisplay = true
                            
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Invalidated layout for specific attachment")
                        } else {
                            // Fallback à l'invalidation complète
                            textView.layoutManager?.invalidateLayout(forCharacterRange: fullRange, actualCharacterRange: nil)
                            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                            textView.needsLayout = true
                            textView.needsDisplay = true
                            self.control?.needsDisplay = true
                            print("KNA - LaTeXAttachmentCell [\(self.cellID)] Invalidated layout for entire text")
                        }
                    }
                }
            }
        }
    }
    
    override func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        return MainActor.assumeIsolated {
            // Utiliser la hauteur exacte si définie, sinon utiliser la hauteur calculée
            let height = exactHeight ?? max(currentSize.height, fontSize * 1.5)
            
            // Vérifier si la hauteur a changé depuis la dernière fois
            let heightChanged = lastFrame.height != height && lastFrame.height != 0
            
            // Stocker le cadre exact pour la vue
            lastFrame = NSRect(x: 0, y: 0, width: lineFrag.width, height: height)
            
            print("KNA - LaTeXAttachmentCell [\(cellID)] cellFrame called with proposedLineFragment: \(lineFrag), position: \(position)")
            print("KNA - LaTeXAttachmentCell [\(cellID)] Returning cell frame with height: \(height)")
            
            // Mettre à jour la vue LaTeX avec la nouvelle largeur si nécessaire
            if latexView.frame.width != lineFrag.width || latexView.frame.height != height {
                latexView.frame = NSRect(x: latexView.frame.origin.x, y: latexView.frame.origin.y, 
                                        width: lineFrag.width, height: height)
            }
            
            // Si la hauteur a changé significativement, forcer une mise à jour du layout
            if heightChanged && height > 0 {
                print("KNA - LaTeXAttachmentCell [\(cellID)] Height changed from \(lastFrame.height) to \(height), scheduling layout update")
                
                // Planifier une mise à jour du layout
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let textView = self.control?.enclosingScrollView?.documentView as? NSTextView {
                        textView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: charIndex, length: 1), actualCharacterRange: nil)
                        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                        textView.needsLayout = true
                        textView.needsDisplay = true
                    }
                }
            }
            
            // Retourner le cadre exact - pas besoin de tampon supplémentaire
            return NSRect(x: 0, y: 0, width: lineFrag.width, height: height)
        }
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        print("KNA - LaTeXAttachmentCell [\(cellID)] draw called with cellFrame: \(cellFrame)")
        self.control = controlView
        
        // Utiliser le cadre exact que nous avons calculé, mais avec l'origine de cellFrame
        var adjustedFrame = lastFrame
        adjustedFrame.origin = cellFrame.origin
        
        // Ajuster l'origine Y pour un meilleur alignement vertical
        // Déplacer légèrement vers le haut pour aligner avec le texte
        adjustedFrame.origin.y -= 8
        
        // S'assurer que la hauteur est à jour avec la valeur exactHeight la plus récente
        if let exactHeight = self.exactHeight {
            adjustedFrame.size.height = exactHeight
            
            // Vérifier si la hauteur a changé significativement
            if abs(adjustedFrame.size.height - latexView.frame.height) > 1 {
                print("KNA - LaTeXAttachmentCell [\(cellID)] Significant height change detected: \(latexView.frame.height) -> \(adjustedFrame.size.height)")
                
                // Forcer une mise à jour du layout après le dessin
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let textView = self.control?.enclosingScrollView?.documentView as? NSTextView else { return }
                    
                    // Trouver l'attachement dans le texte
                    if let textStorage = textView.textStorage {
                        let fullRange = NSRange(location: 0, length: textStorage.length)
                        
                        textStorage.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, stop in
                            if let attachment = value as? NSTextAttachment,
                               let cell = attachment.attachmentCell as? LatexAttachmentCell,
                               cell === self {
                                // Forcer une mise à jour complète du layout pour cet attachement
                                textView.layoutManager?.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
                                textView.layoutManager?.invalidateDisplay(forCharacterRange: range)
                                textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                                textView.needsLayout = true
                                textView.needsDisplay = true
                                stop.pointee = true
                            }
                        }
                    }
                }
            }
        }
        
        // Définir le cadre pour la vue LaTeX
        latexView.frame = adjustedFrame
        
        print("KNA - LaTeXAttachmentCell [\(cellID)] Setting latexView frame to: \(adjustedFrame)")
        
        if latexView.superview == nil {
            // Ajouter la vue une seule fois
            controlView?.addSubview(latexView)
            
            // Forcer la mise à jour de la disposition
            latexView.layoutSubtreeIfNeeded()
            
            print("KNA - LaTeXAttachmentCell [\(cellID)] Added latexView to superview at \(latexView.frame)")
            
            // Journaliser le rectangle visible du textView
            if let textView = controlView as? NSTextView {
                print("KNA - LaTeXAttachmentCell [\(cellID)] TextView visibleRect: \(textView.visibleRect), bounds: \(textView.bounds)")
            }
            
            // Ajouter un observateur de notification pour nettoyer la vue lorsque le texte change
            NotificationCenter.default.addObserver(self,
                                                  selector: #selector(textDidChange),
                                                  name: NSText.didChangeNotification,
                                                  object: controlView)
            
            // Forcer un relayout complet après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self, let textView = controlView as? NSTextView else { return }
                
                // Forcer la mise à jour du layout
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
        } else {
            // Mettre à jour le cadre si nécessaire
            print("KNA - LaTeXAttachmentCell [\(cellID)] Updated latexView frame to \(latexView.frame)")
        }
    }
    
    @objc private func textDidChange(_ notification: Notification) {
        // Lorsque le texte change, nous devons vérifier si notre vue est toujours nécessaire
        if let textView = notification.object as? NSTextView,
           let textStorage = textView.textStorage {
            
            // Vérifier si notre vue est toujours dans la hiérarchie des vues
            if latexView.superview == nil {
                // Notre vue a déjà été supprimée, se désabonner de la notification
                NotificationCenter.default.removeObserver(self, name: NSText.didChangeNotification, object: textView)
                return
            }
            
            // Vérifier si le texte contient encore des pièces jointes
            // Si le texte a été complètement remplacé, notre cellule ne sera plus utilisée
            let range = NSRange(location: 0, length: textStorage.length)
            var foundAttachment = false
            
            textStorage.enumerateAttribute(.attachment, in: range, options: []) { value, attachmentRange, stop in
                if let attachment = value as? NSTextAttachment,
                   let cell = attachment.attachmentCell as? LatexAttachmentCell,
                   cell === self {
                    foundAttachment = true
                    stop.pointee = true
                }
            }
            
            if !foundAttachment {
                print("KNA - LaTeXAttachmentCell [\(cellID)] No longer in use, removing from superview")
                latexView.removeFromSuperview()
                
                // Se désabonner de la notification
                NotificationCenter.default.removeObserver(self, name: NSText.didChangeNotification, object: textView)
            }
        }
    }
    
    override func cellSize() -> NSSize {
        return MainActor.assumeIsolated {
            // Utiliser la hauteur exacte si définie, sinon utiliser la hauteur calculée
            let height = exactHeight ?? max(currentSize.height, fontSize * 1.5)
            let width = control?.bounds.width ?? currentSize.width
            
            // Vérifier si la taille a changé significativement
            let oldSize = lastFrame.size
            if oldSize.width > 0 && oldSize.height > 0 && 
               (abs(oldSize.height - height) > 1 || abs(oldSize.width - width) > 1) {
                print("KNA - LaTeXAttachmentCell [\(cellID)] Size changed in cellSize: \(oldSize) -> (\(width), \(height))")
                
                // Mettre à jour lastFrame pour refléter la nouvelle taille
                lastFrame = NSRect(origin: lastFrame.origin, size: NSSize(width: width, height: height))
                
                // Planifier une mise à jour du layout
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let textView = self.control?.enclosingScrollView?.documentView as? NSTextView else { return }
                    textView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textView.textStorage?.length ?? 0), actualCharacterRange: nil)
                    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                    textView.needsLayout = true
                    textView.needsDisplay = true
                }
            }
            
            let size = NSSize(width: width, height: height)
            print("KNA - LaTeXAttachmentCell [\(cellID)] cellSize returning: \(size)")
            return size
        }
    }
    
    override func cellBaselineOffset() -> NSPoint {
        // Calculer un décalage de ligne de base approprié pour un meilleur alignement vertical
        // Utiliser une valeur négative pour déplacer l'élément vers le haut
        return NSPoint(x: 0, y: -12)
    }
    
    deinit {
        print("KNA - LaTeXAttachmentCell [\(cellID)] Deinitializing")
        
        // Se désabonner de toutes les notifications
        NotificationCenter.default.removeObserver(self)
        
        // Capturer les valeurs nécessaires avant que self ne soit libéré
        MainActor.assumeIsolated {
            if let view = latexView, let superview = view.superview {
                let cellIDCopy = cellID
                
                // Utiliser les valeurs capturées dans le bloc async
                DispatchQueue.main.async {
                    view.removeFromSuperview()
                    print("KNA - LaTeXAttachmentCell [\(cellIDCopy)] Removed latexView from superview in async block")
                }
            }
        }
    }
    
    // Méthode pour accéder à la vue LaTeX
    func getLatexView() -> LatexView? {
        return latexView
    }
}

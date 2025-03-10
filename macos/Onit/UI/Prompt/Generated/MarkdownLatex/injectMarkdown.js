//
//  injectMarkdown.js
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//


try {
    // Récupérer le texte markdown
    let markdownText = `[TEXT]`;
    
    // Détecter si c'est un document LaTeX complet
    const isFullLatexDocument = markdownText.includes('\\documentclass') &&
                               markdownText.includes('\\begin{document}') &&
                               markdownText.includes('\\end{document}');
    
    let renderedHTML = '';
    
    if (isFullLatexDocument) {
        log("Document LaTeX complet détecté");
        
        // Extraire le contenu entre \\begin{document} et \\end{document}
        const documentMatch = markdownText.match(/\\begin{document}([\s\S]*?)\\end{document}/);
        let documentContent = '';
        
        if (documentMatch && documentMatch[1]) {
            documentContent = documentMatch[1].trim();
            log("Contenu du document extrait: " + documentContent.substring(0, 50) + "...");
            
            // Préserver les formules mathématiques
            // Stocker temporairement les formules mathématiques
            const mathFormulas = [];
            let mathCounter = 0;
            
            // Remplacer les formules en bloc par des placeholders
            documentContent = documentContent.replace(/\[([\s\S]*?)\]/g, function(match, formula) {
                const placeholder = `MATH_FORMULA_BLOCK_${mathCounter}`;
                mathFormulas.push({
                    placeholder: placeholder,
                    formula: `$$${formula}$$`
                });
                mathCounter++;
                return placeholder;
            });
            
            // Remplacer les formules inline par des placeholders
            documentContent = documentContent.replace(/\(([\s\S]*?)\)/g, function(match, formula) {
                const placeholder = `MATH_FORMULA_INLINE_${mathCounter}`;
                mathFormulas.push({
                    placeholder: placeholder,
                    formula: `$${formula}$`
                });
                mathCounter++;
                return placeholder;
            });
            
            // Convertir les commandes LaTeX courantes en Markdown
            documentContent = documentContent
                .replace(/\\section{([^}]*)}/g, '## $1')
                .replace(/\\subsection{([^}]*)}/g, '### $1')
                .replace(/\\textbf{([^}]*)}/g, '**$1**')
                .replace(/\\textit{([^}]*)}/g, '*$1*')
                .replace(/\\maketitle/g, '');
                
            // Extraire le titre et l'auteur
            const titleMatch = markdownText.match(/\\title{([^}]*)}/);
            const authorMatch = markdownText.match(/\\author{([^}]*)}/);
            
            if (titleMatch && titleMatch[1]) {
                documentContent = '# ' + titleMatch[1] + '\n\n' + documentContent;
            }
            
            if (authorMatch && authorMatch[1]) {
                documentContent = documentContent + '\n\n*Par ' + authorMatch[1] + '*';
            }
            
            // Restaurer les formules mathématiques
            mathFormulas.forEach(item => {
                documentContent = documentContent.replace(item.placeholder, item.formula);
            });
            
            // Rendre le contenu avec markdown-it
            if (typeof markdownit !== 'undefined' && md) {
                renderedHTML = md.render(documentContent);
                log("Document LaTeX rendu en Markdown");
            } else {
                renderedHTML = '<pre>' + documentContent + '</pre>';
                log("markdown-it non disponible, affichage du texte brut");
            }
        } else {
            renderedHTML = '<p>Erreur: Impossible d\'extraire le contenu du document LaTeX</p>';
            log("Erreur: Impossible d'extraire le contenu du document LaTeX");
        }
    } else {
        // Rendre le markdown normal avec markdown-it
        if (typeof markdownit !== 'undefined' && md) {
            renderedHTML = md.render(markdownText);
            log("Markdown rendu avec markdown-it");
        } else {
            // Fallback si markdown-it n'est pas disponible
            renderedHTML = '<pre>' + markdownText + '</pre>';
            log("markdown-it non disponible, affichage du texte brut");
        }
    }
    
    // Afficher le HTML rendu
    document.getElementById('content').innerHTML = renderedHTML;
    
    // Rendre les formules LaTeX si MathJax est disponible
    if (typeof MathJax !== 'undefined') {
        MathJax.typesetPromise().then(() => {
            log("MathJax rendu terminé");
            updateHeight();
        }).catch(err => {
            log("Erreur MathJax: " + err.message);
            updateHeight();
        });
    } else {
        log("MathJax non disponible");
        updateHeight();
    }
    
    document.getElementById('debug').innerHTML = '<p>Rendu terminé</p>';
} catch(e) {
    document.getElementById('debug').innerHTML = '<p style="color:red">Erreur: ' + e.message + '</p>';
    log("Erreur lors du rendu: " + e.message);
    updateHeight();
}

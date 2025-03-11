//
//  injectMarkdown.js
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//

try {
    let markdownText = `[TEXT]`;
    
    const hasLatexCommands = markdownText.includes('\\documentclass') || 
                            markdownText.includes('\\begin{document}') ||
                            markdownText.includes('\\end{document}');
                            
    const isFullLatexDocument = markdownText.includes('\\documentclass') &&
                               markdownText.includes('\\begin{document}') &&
                               markdownText.includes('\\end{document}');
    
    const isPartialLatexDocument = hasLatexCommands && !isFullLatexDocument;
    let renderedHTML = '';
    
    if (isPartialLatexDocument) {
        renderedHTML = '<div class="latex-generating">Generating LaTeX document...</div>';
    } else if (isFullLatexDocument) {
        const documentMatch = markdownText.match(/\\begin{document}([\s\S]*?)\\end{document}/);
        let documentContent = '';
        
        if (documentMatch && documentMatch[1]) {
            documentContent = documentMatch[1].trim();
            
            const mathFormulas = [];
            let mathCounter = 0;
            
            function createPlaceholder(formula, isDisplay = false) {
                const placeholder = `MATH_FORMULA_${isDisplay ? 'DISPLAY' : 'INLINE'}_${mathCounter++}`;
                mathFormulas.push({
                    placeholder: placeholder,
                    formula: isDisplay ? `$$${formula}$$` : `$${formula}$`
                });
                return placeholder;
            }
            
            documentContent = documentContent
                .replace(/\\section{([^}]*)}/g, (match, content) => {
                    return `## ${content}`;
                })
                .replace(/\\subsection{([^}]*)}/g, (match, content) => {
                    return `### ${content}`;
                })
                .replace(/\\begin{enumerate}([\s\S]*?)\\end{enumerate}/g, (match, content) => {
                    const items = content.split('\\item').filter(item => item.trim());
                    return '\n' + items.map((item, index) => `${index + 1}. ${item.trim()}`).join('\n') + '\n';
                })
                .replace(/\\begin{itemize}([\s\S]*?)\\end{itemize}/g, (match, content) => {
                    const items = content.split('\\item').filter(item => item.trim());
                    return '\n' + items.map(item => {
                        const cleanedItem = item.trim()
                            .replace(/\[\$\\bullet\$\]\s*/, '')
                            .replace(/\[\\bullet\]\s*/, '')
                            .trim();
                        return `* ${cleanedItem}`;
                    }).join('\n') + '\n';
                })
                .replace(/\\left/g, '')
                .replace(/\\right/g, '')
            
            documentContent = documentContent.replace(/\$\$([\s\S]*?)\$\$/g, (match, formula) => {
                return createPlaceholder(formula, true);
            });
            
            documentContent = documentContent.replace(/\$([^\$]*?)\$/g, (match, formula) => {
                return createPlaceholder(formula, false);
            });
            
            documentContent = documentContent
                .replace(/\\section\*{([^}]*)}/g, '## $1')
                .replace(/\\subsection\*{([^}]*)}/g, '### $1')
                .replace(/\\textbf{([^}]*)}/g, '**$1**')
                .replace(/\\textit{([^}]*)}/g, '*$1*')
                .replace(/\\maketitle/g, '')
                .replace(/\\\\(\[|\])/g, '\n\n')
                .replace(/\\%/g, '%');

            const titleMatch = markdownText.match(/\\title{([^}]*)}/);
            const authorMatch = markdownText.match(/\\author{([^}]*)}/);
            
            if (titleMatch && titleMatch[1]) {
                documentContent = '# ' + titleMatch[1] + '\n\n' + documentContent;
            }
            
            if (authorMatch && authorMatch[1]) {
                documentContent = documentContent + '\n\n*By ' + authorMatch[1] + '*';
            }
            
            mathFormulas.forEach(item => {
                documentContent = documentContent.replace(item.placeholder, item.formula);
            });
            
            if (typeof markdownit !== 'undefined' && md) {
                renderedHTML = md.render(documentContent);
            } else {
                renderedHTML = '<pre>' + documentContent + '</pre>';
                log("markdown-it unavailable, render raw text");
            }
        } else {
            renderedHTML = '<p>Error: Can\'t extract LaTeX document</p>';
            log("Error: Can't extract LaTeX document");
        }
    } else {
        if (typeof markdownit !== 'undefined' && md) {
            renderedHTML = md.render(markdownText);
        } else {
            renderedHTML = '<pre>' + markdownText + '</pre>';
            log("markdown-it unavailable, render raw text");
        }
    }
    
    document.getElementById('content').innerHTML = renderedHTML;
    
    if (typeof MathJax !== 'undefined') {
        MathJax.typesetPromise().then(() => {
            updateHeight();
        }).catch(err => {
            log("Error MathJax: " + err.message);
            updateHeight();
        });
    } else {
        log("MathJax unavailable");
        updateHeight();
    }
    
    document.getElementById('debug').innerHTML = '<p>Rendering completed</p>';
} catch(e) {
    document.getElementById('debug').innerHTML = '<p style="color:red">Error: ' + e.message + '</p>';
    log("Error while rendering: " + e.message);
    updateHeight();
}

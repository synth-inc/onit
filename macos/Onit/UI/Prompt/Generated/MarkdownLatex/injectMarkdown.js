//
//  injectMarkdown.js
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//

try {
    log("🟡 Starting markdown/LaTeX processing");
    let markdownText = `[TEXT]`;
    log("📝 Initial text length: " + markdownText.length);
    
    // Traiter directement le contenu sans vérifier latex.js
    processContent();
    
    function processContent() {
    let renderedHTML = '';
        
        const fullRegex = /(.*?)(\\documentclass[\s\S]*?\\end{document})(.*)/s;
        const fullMatch = markdownText.match(fullRegex);
            
        if (fullMatch) {
            const before = fullMatch[1];
            let latexContent = fullMatch[2];
            const after = fullMatch[3];
            
            log("📄 Full LaTeX document detected");
            log("📝 LaTeX content length: " + latexContent.length);
            log("📝 Content before: " + before);
            log("📝 Content after: " + after);

            // Prétraiter le document LaTeX pour gérer les environnements problématiques
            latexContent = preprocessLatexDocument(latexContent);

            if (typeof MathJax !== 'undefined') {
                log("🔄 Using MathJax for rendering LaTeX document");
                renderWithMathJax(before, latexContent, after);
            } else {
                log("❌ MathJax not available");
                renderedHTML = before + "<pre class='latex-code'>" + escapeHtml(latexContent) + "</pre>" + after;
                document.getElementById('content').innerHTML = renderedHTML;
                updateHeight();
            }
        } else {
            // Traitement normal pour le contenu non-LaTeX
            if (typeof markdownit !== 'undefined' && md) {
                log("🔄 Rendering with markdown-it");
                renderedHTML = md.render(markdownText);
                log("✅ Markdown rendered successfully");
            } else {
                log("⚠️ markdown-it unavailable, rendering raw text");
                renderedHTML = '<pre>' + escapeHtml(markdownText) + '</pre>';
            }
            
            log("🎨 Updating DOM with rendered content");
            document.getElementById('content').innerHTML = renderedHTML;
            
            if (typeof MathJax !== 'undefined') {
                log("🔢 Starting MathJax typesetting");
                MathJax.typesetPromise().then(() => {
                    log("✅ MathJax typesetting completed");
                    updateHeight();
                }).catch(err => {
                    log("❌ MathJax error: " + err.message);
                    updateHeight();
                });
            } else {
                log("⚠️ MathJax unavailable");
                updateHeight();
            }
        }
    }
    
    // Fonction pour rendre le document LaTeX avec MathJax
    function renderWithMathJax(before, latexContent, after) {
        log("🔄 Rendering LaTeX with MathJax");
        
        // Extraire le contenu du document (sans les parties preamble et document)
        const bodyRegex = /\\begin\{document\}([\s\S]*?)\\end\{document\}/;
        const bodyMatch = latexContent.match(bodyRegex);
        
        if (bodyMatch && bodyMatch[1]) {
            const bodyContent = bodyMatch[1];
            log("📝 Extracted body content length: " + bodyContent.length);
            
            // Créer un conteneur pour le document LaTeX
            const container = document.createElement('div');
            container.id = 'mathjax-container';
            container.className = 'latex-document';
            
            // Ajouter le contenu au conteneur
            container.innerHTML = bodyContent;
            
            // Construire le HTML final
            document.getElementById('content').innerHTML = before;
            document.getElementById('content').appendChild(container);
            if (after) {
                const afterContainer = document.createElement('div');
                afterContainer.innerHTML = after;
                document.getElementById('content').appendChild(afterContainer);
            }
            
            // Configurer MathJax pour ce rendu spécifique
            configureMathJaxForFullDocument();
            
            // Typeset avec MathJax
            MathJax.typesetPromise().then(() => {
                log("✅ MathJax typesetting completed");
                
                // Post-traitement pour appliquer des styles aux théorèmes et preuves
                postProcessMathJaxContent();
                
                // Ajouter des classes aux tableaux pour le styling
                styleTableElements();
                
                updateHeight();
            }).catch(err => {
                log("❌ MathJax error: " + err.message);
                updateHeight();
            });
        } else {
            log("❌ Could not extract body content from LaTeX document");
            const renderedHTML = before + "<pre class='latex-error'>" + escapeHtml(latexContent) + "</pre>" + after;
            document.getElementById('content').innerHTML = renderedHTML;
            updateHeight();
        }
    }
    
    // Fonction pour configurer MathJax spécifiquement pour les documents LaTeX complets
    function configureMathJaxForFullDocument() {
        try {
            if (typeof MathJax !== 'undefined' && MathJax.config) {
                // Augmenter la taille du buffer pour les documents complexes
                if (MathJax.config.tex) {
                    MathJax.config.tex.maxBuffer = 20 * 1024;
                }
                
                log("✅ MathJax configured for full LaTeX document");
            }
        } catch (e) {
            log("❌ Error configuring MathJax: " + e.message);
        }
    }
    
    // Fonction pour ajouter des styles aux tableaux après le rendu MathJax
    function styleTableElements() {
        try {
            const container = document.getElementById('mathjax-container');
            if (!container) return;
            
            // Ajouter des classes aux tableaux MathJax
            const tables = container.querySelectorAll('table');
            tables.forEach(table => {
                table.classList.add('latex-table');
                
                // Ajouter des classes aux cellules
                const cells = table.querySelectorAll('td');
                cells.forEach(cell => {
                    cell.classList.add('latex-cell');
                });
            });
            
            log(`✅ Styled ${tables.length} tables in the document`);
        } catch (e) {
            log("❌ Error styling tables: " + e.message);
        }
    }
    
    // Fonction pour post-traiter le contenu après le rendu MathJax
    function postProcessMathJaxContent() {
        log("🔄 Post-processing MathJax content");
        
        // Trouver tous les éléments contenant "Théorème." et les envelopper dans un div.theorem
        const container = document.getElementById('mathjax-container');
        if (!container) return;
        
        // Traiter les théorèmes
        const theoremRegex = /\\textbf\{Théorème\.\}\s*([\s\S]*?)(?=\\textbf\{|$)/g;
        let html = container.innerHTML;
        html = html.replace(theoremRegex, '<div class="theorem"><strong>Théorème.</strong> $1</div>');
        
        // Traiter les preuves
        const proofRegex = /\\textbf\{Preuve\.\}\s*([\s\S]*?)(?=\\textbf\{|$)/g;
        html = html.replace(proofRegex, '<div class="proof"><strong>Preuve.</strong> $1</div>');
        
        // Traiter le contenu centré
        const centerRegex = /<div\s+style="text-align:center">([\s\S]*?)<\/div>/g;
        html = html.replace(centerRegex, '<div class="centered-content">$1</div>');
        
        container.innerHTML = html;
        log("✅ Post-processing completed");
    }
    
    // Fonction pour prétraiter le document LaTeX et gérer les environnements problématiques
    function preprocessLatexDocument(latexContent) {
        log("🔄 Preprocessing LaTeX document to handle problematic environments");
        
        // Remplacer l'environnement table par un environnement center avec tabular
        let processedContent = latexContent;
        
        // Traiter les tableaux et les environnements de tableau
        processedContent = processTableEnvironments(processedContent);
        
        // Traiter les listes (itemize, enumerate)
        processedContent = processListEnvironments(processedContent);
        
        // Liste des environnements problématiques à convertir en center
        const problematicEnvironments = [
            'figure', 'center', 'proof', 'theorem', 'verbatim'
        ];
        
        // Traiter chaque environnement problématique
        problematicEnvironments.forEach(env => {
            const envRegex = new RegExp(`[ \\t]*\\\\begin\\{${env}\\}([\\s\\S]*?)[ \\t]*\\\\end\\{${env}\\}`, 'g');
            processedContent = processedContent.replace(envRegex, (match, content) => {
                log(`🔄 Converting ${env} environment to simpler format`);
                
                // Pour center, on utilise un div avec text-align:center
                if (env === 'center') {
                    return `<div style="text-align:center">${content}</div>`;
                }
                
                // Pour theorem et proof, on ajoute un titre
                if (env === 'theorem') {
                    return "\\textbf{Théorème.} " + content;
                }
                
                if (env === 'proof') {
                    return "\\textbf{Preuve.} " + content;
                }
                
                // Pour verbatim, on enveloppe dans un pre
                if (env === 'verbatim') {
                    return `<pre class="verbatim">${content}</pre>`;
                }
                
                // Pour les autres, on garde juste le contenu
                return content;
            });
        });
        
        // Gérer l'environnement equation avec espaces possibles devant
        const equationRegex = /[ \t]*\\begin\{equation\}([\s\S]*?)[ \t]*\\end\{equation\}/g;
        processedContent = processedContent.replace(equationRegex, (match, equationContent) => {
            log("🔄 Converting equation environment to display math notation");
            return "\\[" + equationContent + "\\]";
        });
        
        // Gérer d'autres environnements d'équation
        const mathEnvironments = ['align', 'gather', 'multline', 'eqnarray', 'displaymath'];
        mathEnvironments.forEach(env => {
            const envRegex = new RegExp(`[ \\t]*\\\\begin\\{${env}\\}([\\s\\S]*?)[ \\t]*\\\\end\\{${env}\\}`, 'g');
            processedContent = processedContent.replace(envRegex, (match, content) => {
                log(`🔄 Converting ${env} environment to display math notation`);
                return "\\[" + content + "\\]";
            });
        });
        
        // Remplacer les commandes problématiques
        processedContent = replaceUnsupportedCommands(processedContent);
        
        // Traiter la bibliographie
        const bibRegex = /\\printbibliography/g;
        processedContent = processedContent.replace(bibRegex, () => {
            log("🔄 Converting bibliography to HTML");
            return '<div class="bibliography"><h2>Bibliographie</h2><p>La bibliographie n\'a pas pu être générée.</p></div>';
        });
        
        // Traiter les sections et sous-sections
        processedContent = processedContent.replace(/\\section\{([^}]*)\}/g, (match, title) => {
            return `<h1>${title}</h1>`;
        });
        
        processedContent = processedContent.replace(/\\subsection\{([^}]*)\}/g, (match, title) => {
            return `<h2>${title}</h2>`;
        });
        
        processedContent = processedContent.replace(/\\subsubsection\{([^}]*)\}/g, (match, title) => {
            return `<h3>${title}</h3>`;
        });
        
        // Traiter les titres et auteurs
        processedContent = processedContent.replace(/\\title\{([^}]*)\}/, (match, title) => {
            log("🔄 Extracting document title: " + title);
            return `\\title{${title}}`;
        });
        
        processedContent = processedContent.replace(/\\author\{([^}]*)\}/, (match, author) => {
            log("🔄 Extracting document author: " + author);
            return `\\author{${author}}`;
        });
        
        processedContent = processedContent.replace(/\\maketitle/, () => {
            const titleMatch = latexContent.match(/\\title\{([^}]*)\}/);
            const authorMatch = latexContent.match(/\\author\{([^}]*)\}/);
            
            let titleHtml = '<div class="document-title">';
            if (titleMatch && titleMatch[1]) {
                titleHtml += `<h1>${titleMatch[1]}</h1>`;
            }
            if (authorMatch && authorMatch[1]) {
                titleHtml += `<p class="author">${authorMatch[1]}</p>`;
            }
            titleHtml += '</div>';
            
            return titleHtml;
        });
        
        log("✅ LaTeX preprocessing completed");
        return processedContent;
    }
    
    // Fonction pour traiter les environnements de liste
    function processListEnvironments(content) {
        log("🔄 Processing list environments");
        
        // Traiter l'environnement itemize
        const itemizeRegex = /\\begin\{itemize\}([\s\S]*?)\\end\{itemize\}/g;
        content = content.replace(itemizeRegex, (match, listContent) => {
            log("🔄 Converting itemize environment to HTML list");
            
            // Remplacer chaque \item par un élément de liste HTML
            let htmlList = "<ul class='latex-list'>";
            const items = listContent.split("\\item").filter(item => item.trim() !== "");
            
            items.forEach(item => {
                htmlList += `<li>${item.trim()}</li>`;
            });
            
            htmlList += "</ul>";
            return htmlList;
        });
        
        // Traiter l'environnement enumerate
        const enumerateRegex = /\\begin\{enumerate\}([\s\S]*?)\\end\{enumerate\}/g;
        content = content.replace(enumerateRegex, (match, listContent) => {
            log("🔄 Converting enumerate environment to HTML ordered list");
            
            // Remplacer chaque \item par un élément de liste HTML
            let htmlList = "<ol class='latex-list'>";
            const items = listContent.split("\\item").filter(item => item.trim() !== "");
            
            items.forEach(item => {
                htmlList += `<li>${item.trim()}</li>`;
            });
            
            htmlList += "</ol>";
            return htmlList;
        });
        
        return content;
    }
    
    // Fonction pour traiter spécifiquement les environnements de tableau
    function processTableEnvironments(content) {
        log("🔄 Processing table environments");
        
        // Traiter les environnements tabular directement (pas dans un environnement table)
        const standaloneTabularRegex = /\\begin\{(tabular|tabularx|array|longtable)\}(\{[^}]*\})([\s\S]*?)\\end\{(tabular|tabularx|array|longtable)\}/g;
        content = content.replace(standaloneTabularRegex, (match, envStart, args, tableContent, envEnd) => {
            log(`🔄 Processing standalone ${envStart} environment`);
            
            // Convertir le tableau en HTML
            return convertTabularToHtml(envStart, args, tableContent);
        });
        
        // Traiter les environnements tabular dans un environnement table
        const tabularRegex = /\\begin\{(tabular|tabularx|array|longtable)\}(\{[^}]*\})([\s\S]*?)\\end\{(tabular|tabularx|array|longtable)\}/g;
        content = content.replace(tabularRegex, (match, envStart, args, tableContent, envEnd) => {
            log(`🔄 Processing ${envStart} environment`);
            
            // Simplifier le contenu du tableau
            let processedTable = tableContent
                // Remplacer les commandes de ligne
                .replace(/\\\\(\[.*?\])?/g, '\\\\')
                // Remplacer les commandes de colonne
                .replace(/\\multicolumn\{(\d+)\}\{[^}]*\}\{([^}]*)\}/g, (m, cols, text) => {
                    return text;
                })
                // Remplacer les commandes de ligne horizontale
                .replace(/\\(hline|toprule|midrule|bottomrule|cline\{[^}]*\})/g, '\\hline');
            
            // Reconstruire le tableau avec les arguments originaux
            return `\\begin{${envStart}}${args}${processedTable}\\end{${envStart}}`;
        });
        
        // Traiter les environnements table
        const tableRegex = /\\begin\{table\}(\[.*?\])?([\s\S]*?)\\end\{table\}/g;
        content = content.replace(tableRegex, (match, placement, tableContent) => {
            log("🔄 Processing table environment");
            
            // Extraire la légende si elle existe
            let caption = "";
            const captionMatch = tableContent.match(/\\caption\{([^}]*)\}/);
            if (captionMatch) {
                caption = `<div class="table-caption">${captionMatch[1]}</div>`;
            }
            
            // Vérifier s'il y a un environnement tabular à l'intérieur
            const tabularMatch = tableContent.match(/\\begin\{(tabular|tabularx|array|longtable)\}(\{[^}]*\})([\s\S]*?)\\end\{(tabular|tabularx|array|longtable)\}/);
            if (tabularMatch) {
                const [fullMatch, envType, args, tabularContent] = tabularMatch;
                const htmlTable = convertTabularToHtml(envType, args, tabularContent);
                return `<div class="table-container">${caption}${htmlTable}</div>`;
            }
            
            // Conserver le contenu du tableau
            return `<div class="table-container">${caption}${tableContent}</div>`;
        });
        
        return content;
    }
    
    // Fonction pour convertir un environnement tabular en HTML
    function convertTabularToHtml(envType, args, content) {
        log(`🔄 Converting ${envType} to HTML table`);
        
        // Analyser les spécifications de colonne
        const colSpec = args.replace(/[{}]/g, '');
        const columns = colSpec.split('');
        
        // Créer la table HTML
        let htmlTable = '<table class="latex-table">';
        
        // Traiter les lignes
        const rows = content.split('\\\\').map(row => row.trim()).filter(row => row);
        
        rows.forEach(row => {
            // Ignorer les lignes horizontales
            if (row.trim() === '\\hline' || row.trim() === '\\toprule' || 
                row.trim() === '\\midrule' || row.trim() === '\\bottomrule') {
                return;
            }
            
            // Créer une nouvelle ligne
            htmlTable += '<tr>';
            
            // Diviser la ligne en cellules
            const cells = row.split('&').map(cell => cell.trim());
            
            cells.forEach((cell, index) => {
                // Déterminer l'alignement basé sur la spécification de colonne
                let align = 'center';
                if (index < columns.length) {
                    if (columns[index] === 'l') align = 'left';
                    else if (columns[index] === 'r') align = 'right';
                }
                
                // Ajouter la cellule
                htmlTable += `<td style="text-align: ${align}">${cell}</td>`;
            });
            
            htmlTable += '</tr>';
        });
        
        htmlTable += '</table>';
        return htmlTable;
    }
    
    // Fonction pour remplacer les commandes LaTeX non supportées
    function replaceUnsupportedCommands(content) {
        log("🔄 Replacing unsupported LaTeX commands");
        
        // Dictionnaire des commandes à remplacer
        const commandReplacements = {
            '\\toprule': '\\hline\\hline',
            '\\midrule': '\\hline',
            '\\bottomrule': '\\hline\\hline',
            '\\cmidrule': '\\hline',
            '\\multicolumn': '', // Suppression complète car difficile à remplacer simplement
            '\\includegraphics': '\\textbf{[Image]}', // Remplacer par un texte indicatif
            '\\caption': '\\textbf{Caption:}', // Simplifier la légende
            '\\label': '', // Supprimer les labels
            '\\ref': '??', // Remplacer les références par ??
            '\\cite': '[citation]', // Remplacer les citations
            '\\footnote': '[note]', // Remplacer les notes de bas de page
            '\\printbibliography': '\\textbf{Bibliographie}', // Remplacer la bibliographie
            '\\definecolor': '', // Ignorer les définitions de couleur
            '\\lstset': '', // Ignorer les configurations de listings
            '\\centering': '', // Ignorer centering
            '\\textbf': '\\mathbf', // Convertir textbf en mathbf pour MathJax
            '\\textit': '\\mathit', // Convertir textit en mathit pour MathJax
            '\\textrm': '\\mathrm', // Convertir textrm en mathrm pour MathJax
            '\\hline\\hline': '\\hline', // Simplifier les doubles lignes
            '\\cline': '\\hline', // Simplifier les lignes partielles
            '\\item': '• ', // Remplacer les items par des puces si non traités par processListEnvironments
        };
        
        // Remplacer chaque commande
        Object.keys(commandReplacements).forEach(cmd => {
            const replacement = commandReplacements[cmd];
            const cmdRegex = new RegExp(cmd + '(\\{[^}]*\\})*', 'g');
            content = content.replace(cmdRegex, replacement);
            log(`🔄 Replaced ${cmd} with ${replacement}`);
        });
        
        // Traiter l'environnement lstlisting
        const lstlistingRegex = /\\begin\{lstlisting\}(\[.*?\])?([\s\S]*?)\\end\{lstlisting\}/g;
        content = content.replace(lstlistingRegex, (match, options, codeContent) => {
            log("🔄 Converting lstlisting environment to code block");
            let caption = "";
            if (options && options.includes("caption=")) {
                const captionMatch = options.match(/caption=\{([^}]*)\}/);
                if (captionMatch && captionMatch[1]) {
                    caption = `<div class="code-caption"><strong>Listing:</strong> ${captionMatch[1]}</div>`;
                }
            }
            return `${caption}<pre class="code-block">${codeContent}</pre>`;
        });
        
        content = content.replace(/\\title\{([^}]*)\}/g, '');
        content = content.replace(/\\author\{([^}]*)\}/g, '');
        content = content.replace(/\\date\{([^}]*)\}/g, '');
        
        content = content.replace(/\\section\*?\{([^}]*)\}/g, (match, title) => {
            return `<h1>${title}</h1>`;
        });
        
        content = content.replace(/\\centering/g, '');
        content = content.replace(/\\begin\{centering\}([\s\S]*?)\\end\{centering\}/g, '$1');
        
        return content;
    }
    
    // Fonction pour échapper le HTML
    function escapeHtml(text) {
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }
} catch(e) {
    log("❌ Error while rendering: " + e.message);
    document.getElementById('debug').innerHTML = '<p style="color:red">Error: ' + e.message + '</p>';
    updateHeight();
}

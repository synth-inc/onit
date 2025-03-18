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
    
    // Vérifier si le texte contient des commandes includegraphics et subfigures
    const hasIncludeGraphics = markdownText.includes("\\includegraphics");
    const hasSubfigures = markdownText.includes("\\begin{subfigure}");
    log(`📊 Initial check: includegraphics=${hasIncludeGraphics ? "présent" : "absent"}, subfigures=${hasSubfigures ? "présentes" : "absentes"}`);
    
    // Afficher un échantillon du texte pour débogage
    log("📝 Text sample: " + markdownText.substring(markdownText.indexOf("\\documentclass"), markdownText.indexOf("\\documentclass") + 200));
    
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
            
            // Loguer les 100 premiers caractères du contenu pour débogage
            log("📝 Body content preview: " + bodyContent.substring(0, 100) + "...");
            
            // Chercher des images pour débogage
            const includegraphicsRegex = /\\includegraphics(\[([^\]]*)\])?\{([^}]*)\}/g;
            let imgMatch;
            while ((imgMatch = includegraphicsRegex.exec(bodyContent)) !== null) {
                log(`📊 Found image: ${imgMatch[3]} with options: ${imgMatch[2] || 'none'}`);
            }
            
            // Chercher des subfigures pour débogage
            const subfigRegex = /\\begin\{subfigure\}/g;
            let subfigCount = 0;
            while (subfigRegex.exec(bodyContent) !== null) {
                subfigCount++;
            }
            log(`📊 Found ${subfigCount} subfigures in the document`);
            
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
                
                // Vérifier si des subfigures ont été rendues
                const renderedSubfigures = document.querySelectorAll('.subfigure');
                log(`📊 Rendered ${renderedSubfigures.length} subfigures after processing`);
                
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
        const theoremRegex = /\\textbf\{Theorem\.\}\s*([\s\S]*?)(?=\\textbf\{|$)/g;
        let html = container.innerHTML;
        html = html.replace(theoremRegex, '<div class="theorem"><strong>Theorem.</strong> $1</div>');
        
        // Traiter les preuves
        const proofRegex = /\\textbf\{Proof\.\}\s*([\s\S]*?)(?=\\textbf\{|$)/g;
        html = html.replace(proofRegex, '<div class="proof"><strong>Proof.</strong> $1</div>');
        
        // Traiter le contenu centré
        const centerRegex = /<div\s+style="text-align:center">([\s\S]*?)<\/div>/g;
        html = html.replace(centerRegex, '<div class="centered-content">$1</div>');
        
        container.innerHTML = html;
        log("✅ Post-processing completed");
    }
    
    // Fonction pour prétraiter le document LaTeX et gérer les environnements problématiques
    function preprocessLatexDocument(latexContent) {
        log("🔄 Preprocessing LaTeX document to handle problematic environments");
        
        // Normaliser le contenu LaTeX pour éviter les problèmes d'échappement
        let processedContent = normalizeLatexCommands(latexContent);
        
        // Garder une trace des labels pour les références
        const labelMap = {};
        
        // Extraire les labels et les associer à leur environnement
        const labelRegex = /\\label\{([^}]*)\}/g;
        let labelMatch;
        while ((labelMatch = labelRegex.exec(processedContent)) !== null) {
            const label = labelMatch[1];
            
            // Trouver le type d'environnement contenant ce label
            let envType = "unknown";
            let envNumber = "??";
            
            // Vérifier si le label est dans une figure
            const figureCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\begin{figure}");
            const figureEndCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\end{figure}");
            if (figureCheck > figureEndCheck && figureCheck !== -1) {
                envType = "figure";
                
                // Extraire le numéro de la figure (implémentation simplifiée)
                // Dans une vraie implémentation, on compterait les figures
                envNumber = countEnvironment(processedContent, "figure", labelMatch.index);
            }
            
            // Vérifier si le label est dans une table
            const tableCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\begin{table}");
            const tableEndCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\end{table}");
            if (tableCheck > tableEndCheck && tableCheck !== -1) {
                envType = "table";
                envNumber = countEnvironment(processedContent, "table", labelMatch.index);
            }
            
            // Vérifier si le label est dans une équation
            const equationCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\begin{equation}");
            const equationEndCheck = processedContent.substring(0, labelMatch.index).lastIndexOf("\\end{equation}");
            if (equationCheck > equationEndCheck && equationCheck !== -1) {
                envType = "equation";
                envNumber = countEnvironment(processedContent, "equation", labelMatch.index);
            }
            
            // Stocker les informations du label
            labelMap[label] = {
                type: envType,
                number: envNumber
            };
            
            log(`🔖 Found label: ${label} (${envType} ${envNumber})`);
        }
        
        // Remplacer les \ref par les numéros correspondants
        processedContent = processedContent.replace(/\\ref\{([^}]*)\}/g, (match, label) => {
            if (labelMap[label]) {
                const ref = labelMap[label];
                log(`🔄 Replacing reference to ${label} with ${ref.number}`);
                return ref.number;
            } else {
                log(`⚠️ Reference to unknown label: ${label}`);
                return "??";
            }
        });
        
        // IMPORTANT: Traiter les figures et sous-figures AVANT de remplacer les commandes
        // Cela permet de préserver les commandes \includegraphics pour le traitement des figures
        processedContent = processTableEnvironments(processedContent);
        processedContent = processListEnvironments(processedContent);
        processedContent = processFigureEnvironments(processedContent);
        
        // Maintenant, remplacer les commandes problématiques
        processedContent = replaceUnsupportedCommands(processedContent);
        
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
                    return "\\textbf{Theorem.} " + content;
                }
                
                if (env === 'proof') {
                    return "\\textbf{Proof.} " + content;
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
    
    // Fonction pour normaliser les commandes LaTeX et corriger les problèmes d'échappement
    function normalizeLatexCommands(content) {
        log("🔄 Normalizing LaTeX commands");
        
        // Corriger les doubles backslashes (sauf dans les newlines et tabulations)
        let normalizedContent = content.replace(/\\\\(?![rnt])/g, "\\");
        
        // S'assurer que les commandes includegraphics sont correctement formatées
        normalizedContent = normalizedContent.replace(/\\\\includegraphics/g, "\\includegraphics");
        
        // Normaliser les options de includegraphics
        normalizedContent = normalizedContent.replace(/\\includegraphics\s*\[/g, "\\includegraphics[");
        
        // Corriger les problèmes éventuels dans les subfigures
        normalizedContent = normalizedContent.replace(/\\\\begin\{subfigure\}/g, "\\begin{subfigure}");
        normalizedContent = normalizedContent.replace(/\\\\end\{subfigure\}/g, "\\end{subfigure}");
        
        // Corriger les problèmes éventuels avec les captions
        normalizedContent = normalizedContent.replace(/\\\\caption/g, "\\caption");
        
        // Corriger les problèmes éventuels avec les centering
        normalizedContent = normalizedContent.replace(/\\\\centering/g, "\\centering");
        
        log("✅ LaTeX commands normalized");
        return normalizedContent;
    }
    
    // Fonction pour compter les environnements jusqu'à un certain point dans le document
    function countEnvironment(content, envType, endIndex) {
        const regex = new RegExp(`\\\\begin\\{${envType}\\}`, 'g');
        let match;
        let count = 0;
        
        // Limiter la recherche jusqu'à l'index spécifié
        const searchText = content.substring(0, endIndex);
        
        while ((match = regex.exec(searchText)) !== null) {
            count++;
        }
        
        return count.toString();
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
            
            // Extraire l'identifiant de label s'il existe
            let tableId = "";
            const labelMatch = tableContent.match(/\\label\{([^}]*)\}/);
            if (labelMatch) {
                tableId = `id="tab-${labelMatch[1]}"`;
                log(`🔖 Table has label: ${labelMatch[1]}`);
            }
            
            // Extraire la légende si elle existe
            let caption = "";
            const captionMatch = tableContent.match(/\\caption\{([^}]*)\}/);
            if (captionMatch) {
                caption = `<div class="table-caption"><strong>Table:</strong> ${captionMatch[1]}</div>`;
            }
            
            // Vérifier s'il y a un environnement tabular à l'intérieur
            const tabularMatch = tableContent.match(/\\begin\{(tabular|tabularx|array|longtable)\}(\{[^}]*\})([\s\S]*?)\\end\{(tabular|tabularx|array|longtable)\}/);
            if (tabularMatch) {
                const [fullMatch, envType, args, tabularContent] = tabularMatch;
                const htmlTable = convertTabularToHtml(envType, args, tabularContent);
                return `<div class="table-container" ${tableId}>${caption}${htmlTable}</div>`;
            }
            
            // Conserver le contenu du tableau
            return `<div class="table-container" ${tableId}>${caption}${tableContent}</div>`;
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
        
        // Ne pas remplacer includegraphics maintenant car cela peut interférer avec la détection des subfigures
        // On le traitera directement dans processFigureEnvironments
        
        // Dictionnaire des commandes à remplacer
        const commandReplacements = {
            '\\toprule': '\\hline\\hline',
            '\\midrule': '\\hline',
            '\\bottomrule': '\\hline\\hline',
            '\\cmidrule': '\\hline',
            '\\multicolumn': '', // Suppression complète car difficile à remplacer simplement
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
    
    // Fonction pour traiter les environnements de figure et subfigure
    function processFigureEnvironments(content) {
        log("🔄 Processing figure environments");
        
        // Accéder à la carte des labels (définie dans preprocessLatexDocument)
        // On utilisera une approche différente pour intégrer les références
        
        // Traiter les figures avec subfigures
        content = content.replace(/\\begin\{figure\}(\[.*?\])?([\s\S]*?)\\end\{figure\}/g, (match, placement, figureContent) => {
            // Vérifier si cette figure contient des subfigures
            if (figureContent.includes('\\begin{subfigure}')) {
                log("🔄 Converting figure with subfigures to HTML");
                
                // Extraire l'identifiant de label s'il existe
                let figureId = "";
                const labelMatch = figureContent.match(/\\label\{([^}]*)\}/);
                if (labelMatch) {
                    figureId = `id="fig-${labelMatch[1]}"`;
                    log(`🔖 Figure has label: ${labelMatch[1]}`);
                }
                
                // Extraire la légende principale
                const mainCaptionMatch = figureContent.match(/\\caption\{([^}]*)\}/);
                const mainCaption = mainCaptionMatch ? mainCaptionMatch[1] : "";
                
                // Extraire toutes les subfigures
                const subfigures = [];
                const subfigureRegex = /\\begin\{subfigure\}(\{[^}]*\})([\s\S]*?)\\end\{subfigure\}/g;
                let subfigMatch;
                
                while ((subfigMatch = subfigureRegex.exec(figureContent)) !== null) {
                    const size = subfigMatch[1];
                    const content = subfigMatch[2];
                    
                    // Extraire l'image avec un regex correct pour includegraphics
                    // Le pattern inclut les crochets optionnels et les accolades obligatoires
                    const imageMatch = content.match(/\\includegraphics(\[([^\]]*)\])?\{([^}]*)\}/);
                    const captionMatch = content.match(/\\caption\{([^}]*)\}/);
                    
                    // Extraire le label de la subfigure si présent
                    let subfigId = "";
                    const sublabelMatch = content.match(/\\label\{([^}]*)\}/);
                    if (sublabelMatch) {
                        subfigId = `id="fig-${sublabelMatch[1]}"`;
                        log(`🔖 Subfigure has label: ${sublabelMatch[1]}`);
                    }
                    
                    subfigures.push({
                        size: size,
                        imagePath: imageMatch ? imageMatch[3] : null, // Chemin est dans group 3 maintenant
                        imageOptions: imageMatch ? imageMatch[2] : null, // Options dans group 2
                        caption: captionMatch ? captionMatch[1] : null,
                        id: subfigId
                    });
                    
                    log(`📊 Extracted subfigure: ${imageMatch ? imageMatch[3] : 'No image'}`);
                }
                
                log(`🔄 Found ${subfigures.length} subfigures`);
                
                // Créer le HTML pour les subfigures
                let subfiguresHtml = '<div class="subfigures-container">';
                
                // Ajouter chaque subfigure
                subfigures.forEach((subfig, index) => {
                    subfiguresHtml += `<div class="subfigure" ${subfig.id}>`;
                    if (subfig.imagePath) {
                        subfiguresHtml += `<div class="subfigure-image">[Image: ${subfig.imagePath}${subfig.imageOptions ? ' avec options: ' + subfig.imageOptions : ''}]</div>`;
                    }
                    if (subfig.caption) {
                        subfiguresHtml += `<div class="subfigure-caption">${subfig.caption}</div>`;
                    }
                    subfiguresHtml += '</div>';
                });
                
                // Fermer le conteneur des subfigures
                subfiguresHtml += '</div>';
                
                // Ajouter la légende principale
                if (mainCaption) {
                    subfiguresHtml += `<div class="figure-caption"><strong>Figure:</strong> ${mainCaption}</div>`;
                }
                
                // Encapsuler dans un conteneur de figure avec l'ID de figure
                return `<div class="figure-container" ${figureId}>${subfiguresHtml}</div>`;
            } else {
                // Traiter l'environnement figure standard (sans subfigures)
                log("🔄 Converting standard figure to HTML");
                
                // Extraire l'image avec un regex correct
                const imageMatch = figureContent.match(/\\includegraphics(\[([^\]]*)\])?\{([^}]*)\}/);
                const captionMatch = figureContent.match(/\\caption\{([^}]*)\}/);
                
                // Extraire l'identifiant de label s'il existe
                let figureId = "";
                const labelMatch = figureContent.match(/\\label\{([^}]*)\}/);
                if (labelMatch) {
                    figureId = `id="fig-${labelMatch[1]}"`;
                    log(`🔖 Figure has label: ${labelMatch[1]}`);
                }
                
                let figureHtml = `<div class="figure-container" ${figureId}>`;
                
                // Ajouter l'image
                if (imageMatch) {
                    const imagePath = imageMatch[3]; // Chemin est dans group 3 maintenant
                    const imageOptions = imageMatch[2]; // Options dans group 2
                    figureHtml += `<div class="figure-image">[Image: ${imagePath}${imageOptions ? ' avec options: ' + imageOptions : ''}]</div>`;
                    log(`📊 Extracted figure image: ${imagePath}`);
                }
                
                // Ajouter la légende
                if (captionMatch) {
                    figureHtml += `<div class="figure-caption"><strong>Figure:</strong> ${captionMatch[1]}</div>`;
                }
                
                figureHtml += '</div>';
                return figureHtml;
            }
        });
        
        // Traiter l'environnement subfigure individuel (au cas où)
        const subfigureRegex = /\\begin\{subfigure\}(\{[^}]*\})([\s\S]*?)\\end\{subfigure\}/g;
        content = content.replace(subfigureRegex, (match, size, subfigContent) => {
            log("🔄 Converting standalone subfigure to HTML");
            
            // Extraire l'image avec un regex correct
            const imageMatch = subfigContent.match(/\\includegraphics(\[([^\]]*)\])?\{([^}]*)\}/);
            const captionMatch = subfigContent.match(/\\caption\{([^}]*)\}/);
            
            // Extraire le label s'il existe
            let subfigId = "";
            const labelMatch = subfigContent.match(/\\label\{([^}]*)\}/);
            if (labelMatch) {
                subfigId = `id="fig-${labelMatch[1]}"`;
                log(`🔖 Standalone subfigure has label: ${labelMatch[1]}`);
            }
            
            let subfigureHtml = `<div class="subfigure" ${subfigId}>`;
            
            // Ajouter l'image
            if (imageMatch) {
                const imagePath = imageMatch[3]; // Chemin est dans group 3 maintenant
                const imageOptions = imageMatch[2]; // Options dans group 2
                subfigureHtml += `<div class="subfigure-image">[Image: ${imagePath}${imageOptions ? ' avec options: ' + imageOptions : ''}]</div>`;
                log(`📊 Extracted standalone subfigure image: ${imagePath}`);
            }
            
            // Ajouter la légende
            if (captionMatch) {
                subfigureHtml += `<div class="subfigure-caption">${captionMatch[1]}</div>`;
            }
            
            subfigureHtml += '</div>';
            return subfigureHtml;
        });
        
        return content;
    }
} catch(e) {
    log("❌ Error while rendering: " + e.message);
    document.getElementById('debug').innerHTML = '<p style="color:red">Error: ' + e.message + '</p>';
    updateHeight();
}
//
//  markdownLatexScript.js
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//


// Fonction de log pour envoyer des messages à Swift
function log(message) {
    try {
        window.webkit.messageHandlers.logHandler.postMessage(message);
        console.log(message);
    } catch (e) {
        console.error("Erreur lors de l'envoi du log:", e);
    }
}

log("Script démarré");

// Fonction pour mettre à jour la hauteur
function updateHeight() {
    try {
        const height = document.body.scrollHeight;
        window.webkit.messageHandlers.heightHandler.postMessage(height);
        log("Hauteur mise à jour: " + height);
    } catch (e) {
        log("Erreur lors de la mise à jour de la hauteur: " + e.message);
    }
}

// Fonctions de traitement des environnements LaTeX
function processTabular(content) {
    try {
        // Extraire les spécifications des colonnes
        const lines = content.trim().split('\\\\');
        const rows = lines.map(line => {
            return line.split('&').map(cell => cell.trim());
        });

        // Construire le tableau HTML
        let html = '<div class="latex-table"><table>';
        rows.forEach((row, rowIndex) => {
            html += '<tr>';
            row.forEach(cell => {
                if (cell.includes('\\hline')) {
                    return; // Ignorer les lignes horizontales
                }
                html += `<td>${cell}</td>`;
            });
            html += '</tr>';
        });
        html += '</table></div>';
        return html;
    } catch (err) {
        log("Erreur lors du traitement du tableau: " + err.message);
        return `<pre class="latex-error">Erreur de tableau: ${content}</pre>`;
    }
}

function processItemize(content) {
    try {
        const items = content.split('\\item').filter(item => item.trim());
        let html = '<ul class="latex-list">';
        items.forEach(item => {
            html += `<li>${item.trim()}</li>`;
        });
        html += '</ul>';
        return html;
    } catch (err) {
        log("Erreur lors du traitement de la liste: " + err.message);
        return `<pre class="latex-error">Erreur de liste: ${content}</pre>`;
    }
}

function processFigure(content) {
    try {
        const centeringMatch = content.match(/\\centering/);
        const graphicsMatch = content.match(/\\includegraphics(?:\[([^\]]*)\])?{([^}]*)}/);
        const captionMatch = content.match(/\\caption{([^}]*)}/);

        let html = '<figure class="latex-figure">';
        
        if (graphicsMatch) {
            const options = graphicsMatch[1] || '';
            const file = graphicsMatch[2];
            let width = 100;
            
            // Extraire la largeur si elle existe
            if (options && options.includes('width')) {
                const widthMatch = options.match(/width=([\d.]+)\\textwidth/);
                if (widthMatch && widthMatch[1]) {
                    width = parseFloat(widthMatch[1]) * 100;
                }
            }
            
            html += `<img src="${file}" style="width: ${width}%;">`;
        }
        
        if (captionMatch) {
            html += `<figcaption>${captionMatch[1]}</figcaption>`;
        }
        
        html += '</figure>';
        return html;
    } catch (err) {
        log("Erreur lors du traitement de la figure: " + err.message);
        return `<pre class="latex-error">Erreur de figure: ${content}</pre>`;
    }
}

function processEquation(content) {
    try {
        return `<div class="latex-equation">$$${content}$$</div>`;
    } catch (err) {
        log("Erreur lors du traitement de l'équation: " + err.message);
        return `<pre class="latex-error">Erreur d'équation: ${content}</pre>`;
    }
}

// Vérifier si les bibliothèques sont chargées
log("markdown-it disponible: " + (typeof markdownit !== 'undefined'));
log("highlight.js disponible: " + (typeof hljs !== 'undefined'));
log("MathJax disponible: " + (typeof MathJax !== 'undefined'));
log("KaTeX disponible: " + (typeof katex !== 'undefined'));

// Initialiser markdown-it avec highlight.js
let md;
try {
    md = markdownit({
        html: true,
        linkify: true,
        typographer: true,
    highlight: function (str, lang) {
            // Traitement spécial pour les blocs LaTeX
            if (lang === 'latex') {
                try {
                    // Extraire le contenu LaTeX et le traiter directement comme une formule mathématique
                    const latexContent = str.trim();
                    return `<div class="latex-equation">$$${latexContent}$$</div>`;
                } catch (err) {
                    log("Erreur lors du traitement LaTeX: " + err.message);
                    return `<pre><code class="latex-error">${md.utils.escapeHtml(str)}</code></pre>`;
                }
            }
            
            // Traitement normal pour les autres langages
            if (lang && hljs && hljs.getLanguage) {
                try {
                    if (hljs.getLanguage(lang)) {
                        const highlighted = hljs.highlight(str, { language: lang }).value;
                        return `<div class="code-container"><div class="code-title-bar"><span class="language">${lang}</span><div class="copy-button" onclick="copyCode(this)"></div></div><div class="code-content"><pre><code class="hljs language-${lang}">${highlighted}</code></pre></div></div>`;
                    }
                } catch (err) {
                    log("Erreur highlight: " + err.message);
                }
            }
            
            // Fallback pour les autres langages
            return `<div class="code-container"><div class="code-title-bar"><span class="language">${lang || 'texte'}</span><div class="copy-button" onclick="copyCode(this)"></div></div><div class="code-content"><pre><code>${md.utils.escapeHtml(str)}</code></pre></div></div>`;
        }
    });
    
    // Ajouter un préprocesseur pour traiter le LaTeX en dehors des blocs de code
    const defaultRender = md.renderer.rules.text || function(tokens, idx, options, env, self) {
        return tokens[idx].content;
    };

    md.renderer.rules.text = function(tokens, idx, options, env, self) {
        let content = tokens[idx].content;
        
        // Traiter les formules mathématiques en dehors des blocs de code
        content = content
            // Préserver les underscores dans les expressions LaTeX
            .replace(/\\\\_/g, '_')
            // Traiter les expressions mathématiques display
            .replace(/\\\\\[([\\s\\S]*?)\\\\\]/g, (match, formula) => {
                return `$$${formula}$$`;
            })
            // Traiter les expressions mathématiques inline
            .replace(/\\\\\(([\\s\\S]*?)\\\\\)/g, (match, formula) => {
                return `$${formula}$`;
            });
            
        tokens[idx].content = content;
        return defaultRender(tokens, idx, options, env, self);
    };

    // Ajouter un préprocesseur pour le texte brut
    md.core.ruler.before('normalize', 'handle_latex', state => {
        state.src = state.src
            .replace(/\\\\_/g, '_')
            .replace(/\\\\\[([\\s\\S]*?)\\\\\]/g, (match, formula) => {
                return `$$${formula}$$`;
            })
            .replace(/\\\\\(([\\s\\S]*?)\\\\\)/g, (match, formula) => {
                return `$${formula}$`;
            });
    });
    
    log("markdown-it initialisé avec succès");
} catch (e) {
    log("Erreur lors de l'initialisation de markdown-it: " + e.message);
    try {
        md = markdownit({ html: true });
        log("markdown-it initialisé en mode simple");
    } catch (err) {
        log("Échec complet de l'initialisation de markdown-it: " + err.message);
    }
}

// Fonction pour traiter le contenu après le rendu markdown
function postProcessContent(content) {
    // Traiter les formules mathématiques qui pourraient être dans le HTML
    content = content
        .replace(/\\\\_/g, '_')
        .replace(/\\\\\[([\\s\\S]*?)\\\\\]/g, (match, formula) => {
            return `$$${formula}$$`;
        })
        .replace(/\\\\\(([\\s\\S]*?)\\\\\)/g, (match, formula) => {
            return `$${formula}$`;
        });
        
    return content;
}

// Fonction pour rendre les formules mathématiques
function renderMathJax() {
    return new Promise((resolve, reject) => {
        try {
            if (typeof MathJax === 'undefined') {
                log("MathJax n'est pas encore chargé");
                resolve();
                return;
            }

            if (typeof MathJax.typesetPromise !== 'function') {
                log("MathJax n'est pas complètement initialisé, attente...");
                // Attendre que MathJax soit prêt
                setTimeout(() => {
                    if (typeof MathJax.typesetPromise === 'function') {
                        MathJax.typesetPromise()
                            .then(() => {
                                log("MathJax rendu terminé (après attente)");
                                resolve();
                            })
                            .catch(err => {
                                log("Erreur MathJax (après attente): " + err.message);
                                resolve();
                            });
                    } else {
                        log("MathJax toujours pas prêt après attente");
                        resolve();
                    }
                }, 1000);
            } else {
                MathJax.typesetPromise()
                    .then(() => {
                        log("MathJax rendu terminé");
                        resolve();
                    })
                    .catch(err => {
                        log("Erreur MathJax: " + err.message);
                        resolve();
                    });
            }
        } catch (err) {
            log("Erreur lors du rendu MathJax: " + err.message);
            resolve();
        }
    });
}

// Modifier la fonction de mise à jour du contenu
function updateContent(markdownText) {
    try {
        let renderedHTML = '';
        
        if (typeof markdownit !== 'undefined' && md) {
            renderedHTML = md.render(markdownText);
            renderedHTML = postProcessContent(renderedHTML);
            log("Markdown rendu avec markdown-it");
        } else {
            renderedHTML = '<pre>' + markdownText + '</pre>';
            log("markdown-it non disponible, affichage du texte brut");
        }
        
        document.getElementById('content').innerHTML = renderedHTML;
        
        // Rendre les formules LaTeX avec la nouvelle fonction
        renderMathJax().then(() => {
            updateHeight();
        });
    } catch (e) {
        document.getElementById('debug').innerHTML = '<p style="color:red">Erreur: ' + e.message + '</p>';
        log("Erreur lors du rendu: " + e.message);
        updateHeight();
    }
}

// Mettre à jour la hauteur au chargement
window.onload = function() {
    log("Événement onload déclenché");
    setTimeout(() => {
        if (typeof katex !== 'undefined') {
            renderMathInElement(document.body, {
                delimiters: [
                    {left: '$$', right: '$$', display: true},
                    {left: '$', right: '$', display: false},
                    {left: '\(', right: '\)', display: false},
                    {left: '\[', right: '\]', display: true}
                ],
                throwOnError: false
            });
        }
        updateHeight();
    }, 500);
};

// Fonction pour copier le code
function copyCode(button) {
    const container = button.closest('.code-container');
    const code = container.querySelector('code').textContent;
    
    navigator.clipboard.writeText(code).catch(err => {
        log("Erreur lors de la copie: " + err.message);
    });
}

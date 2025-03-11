//
//  markdownLatexScript.js
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//

function log(message) {
    try {
        window.webkit.messageHandlers.logHandler.postMessage(message);
        console.log(message);
    } catch (e) {
        console.error("Erreur lors de l'envoi du log:", e);
    }
}

MathJax = {
    tex: {
        packages: ['base', 'ams', 'noerrors', 'noundefined', 'newcommand', 'boldsymbol', 'color', 'cancel', 'cases', 'mathtools', 'physics', 'configmacros'],
        inlineMath: [['$', '$'], ['\\(', '\\)']],
        displayMath: [['$$', '$$'], ['\\[', '\\]']],
        processEscapes: false,
        processEnvironments: true,
        processRefs: true,
        digits: /^(?:[0-9]+(?:\{,\}[0-9]{3})*(?:\.[0-9]*)?|\.[0-9]+)/,
        tags: 'all',
        tagSide: 'right',
        tagIndent: '0.8em',
        useLabelIds: true,
        maxMacros: 10000,
        maxBuffer: 5 * 1024,
        formatError: (jax, err) => {
            return jax.formatError(err);
        }
    },
    options: {
        skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code'],
        processHtmlClass: 'math',
        ignoreHtmlClass: 'no-math'
    },
    loader: {
        load: ['[tex]/ams', '[tex]/newcommand', '[tex]/boldsymbol', '[tex]/color', '[tex]/cancel', '[tex]/cases', '[tex]/mathtools']
    },
    startup: {
        ready: () => {
            MathJax.startup.defaultReady();
            MathJax.startup.promise.then(() => { });
        }
    }
};

function updateHeight() {
    setTimeout(() => {
        const content = document.getElementById('content');
        const contentHeight = content.getBoundingClientRect().height;
        const spacerHeight = 0;
        const totalHeight = contentHeight + spacerHeight;
        
        window.webkit.messageHandlers.heightHandler.postMessage(totalHeight);
    }, 100);
}

// Init markdown-it with highlight.js
let md;
try {
    md = markdownit({
        html: true,
        linkify: true,
        typographer: true,
        highlight: function (str, lang) {
            if (lang === 'latex') {
                try {
                    const latexContent = str.trim();
                    
                    return `<div class="latex-equation">$$${latexContent}$$</div>`;
                } catch (err) {
                    log("Error with LaTeX: " + err.message);
                    return `<pre><code class="latex-error">${md.utils.escapeHtml(str)}</code></pre>`;
                }
            }
            
            if (lang && hljs && hljs.getLanguage) {
                try {
                    if (hljs.getLanguage(lang)) {
                        const highlighted = hljs.highlight(str, { language: lang }).value;
                        return `<div class="code-container"><div class="code-title-bar"><span class="language">${lang}</span><div class="copy-button" onclick="copyCode(this)"></div></div><div class="code-content"><pre><code class="hljs language-${lang}">${highlighted}</code></pre></div></div>`;
                    }
                } catch (err) {
                    log("Error highlight: " + err.message);
                }
            }
            
            return `<div class="code-container"><div class="code-title-bar"><span class="language">${lang || 'texte'}</span><div class="copy-button" onclick="copyCode(this)"></div></div><div class="code-content"><pre><code class="plaintext">${md.utils.escapeHtml(str)}</code></pre></div></div>`;
        }
    });
    
    const defaultRender = md.renderer.rules.text || function(tokens, idx, options, env, self) {
        return tokens[idx].content;
    };

    md.renderer.rules.text = function(tokens, idx, options, env, self) {
        let content = tokens[idx].content;
        
        content = content
            .replace(/\\\\_/g, '_')
            .replace(/\\\\\[([\\s\\S]*?)\\\\\]/g, (match, formula) => {
                return `$$${formula}$$`;
            })
            .replace(/\\\\\(([\\s\\S]*?)\\\\\)/g, (match, formula) => {
                return `$${formula}$`;
            });
            
        tokens[idx].content = content;
        return defaultRender(tokens, idx, options, env, self);
    };

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
} catch (e) {
    log("Error while initializing markdown-it: " + e.message);
    try {
        md = markdownit({ html: true });
    } catch (err) {
        log("Failed initializing markdown-it: " + err.message);
    }
}

function postProcessContent(content) {
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

function renderMathJax() {
    return new Promise((resolve, reject) => {
        try {
            if (typeof MathJax === 'undefined') {
                resolve();
                return;
            }

            if (typeof MathJax.typesetPromise !== 'function') {
                setTimeout(() => {
                    if (typeof MathJax.typesetPromise === 'function') {
                        MathJax.typesetPromise()
                            .then(() => { resolve(); })
                            .catch(err => {
                                log("Error MathJax (after delay): " + err.message);
                                resolve();
                            });
                    } else {
                        resolve();
                    }
                }, 100);
            } else {
                MathJax.typesetPromise()
                    .then(() => { resolve(); })
                    .catch(err => {
                        log("Error MathJax: " + err.message);
                        resolve();
                    });
            }
        } catch (err) {
            log("Error while rendering MathJax: " + err.message);
            resolve();
        }
    });
}

function updateContent(markdownText) {
    try {
        let renderedHTML = '';
        
        if (typeof markdownit !== 'undefined' && md) {
            renderedHTML = md.render(markdownText);
            renderedHTML = postProcessContent(renderedHTML);
        } else {
            renderedHTML = '<pre>' + markdownText + '</pre>';
            log("markdown-it unavailable, render raw text");
        }
        
        document.getElementById('content').innerHTML = renderedHTML;
        
        renderMathJax().then(() => { updateHeight(); });
    } catch (e) {
        document.getElementById('debug').innerHTML = '<p style="color:red">Erreur: ' + e.message + '</p>';
        log("Error while rendering: " + e.message);
        updateHeight();
    }
}

window.onload = function() {
    setTimeout(() => {
        if (typeof katex !== 'undefined') {
            renderMathInElement(document.body, {
                delimiters: [
                    {left: '$$', right: '$$', display: true},
                    {left: '$', right: '$', display: false},
                    {left: '\\(', right: '\\)', display: false},
                    {left: '\\[', right: '\\]', display: true}
                ],
                throwOnError: false,
                ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
            });
        }
        updateHeight();
    }, 100);
};

function copyCode(button) {
    const container = button.closest('.code-container');
    const code = container.querySelector('code').textContent;
    
    navigator.clipboard.writeText(code).catch(err => {
        log("Error while copying: " + err.message);
    });
}

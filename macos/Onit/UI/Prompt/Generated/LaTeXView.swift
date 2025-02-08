import SwiftUI
import WebKit

struct LaTeXView: NSViewRepresentable {
    let latex: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            <style>
                body { margin: 0; padding: 0; background: transparent; }
                .katex { font-size: 1.1em; }
            </style>
        </head>
        <body>
            <div id="formula"></div>
            <script>
                katex.render("\(latex)", formula, {
                    throwOnError: false,
                    displayMode: true
                });
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (height, error) in
                if let height = height as? CGFloat {
                    webView.frame.size.height = height
                }
            }
        }
    }
}
//
//  WebContentFetchService.swift
//  Onit
//
//  Created by Loyd Kim on 3/24/25.
//

import Foundation
import SwiftSoup
import PDFKit
import WebKit

// This class is used in `Model+Input.swift` (extends `OnitModel.swift`) to
// allow webpage content parsing for web contexts.

class WebContentFetchService {
    static func fetchWebpageContent(websiteUrl: URL) async throws -> (URL, String) {
        // Check Content-Type header.
        let (_, response) = try await URLSession.shared.data(from: websiteUrl)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse(message: websiteUrl.absoluteString)
        }
        
        let invalidWebpageInstruction = "If the webpage content is empty, requires authentication, or doesn't show valid content, just respond telling me that."
        
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           (
            contentType.lowercased().contains("application/pdf") ||
            contentType.lowercased().contains("application/x-pdf") ||
            contentType.lowercased().contains("application/vnd.pdf") ||
            contentType.lowercased().contains("application/acrobat") ||
            websiteUrl.pathExtension.lowercased() == "pdf"
           ){
            return try await fetchPDFContent(websiteUrl: websiteUrl, invalidWebpageInstruction: invalidWebpageInstruction)
        } else {
            return try await fetchHTMLContent(websiteUrl: websiteUrl, invalidWebpageInstruction: invalidWebpageInstruction)
        }
    }
    
    private static func fetchPDFContent(websiteUrl: URL, invalidWebpageInstruction: String) async throws -> (URL, String) {
        let (data, response) = try await URLSession.shared.data(from: websiteUrl)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FetchingError.invalidResponse(message: websiteUrl.absoluteString)
        }
        
        // Maintaining context to the original PDF file.
        let tempPdfUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(websiteUrl.lastPathComponent)
            .appendingPathExtension("pdf")
        try data.write(to: tempPdfUrl)
        
        if let pdfDocument = PDFDocument(data: data) {
            let contentTitle = "Title: \(pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? "Unknown")"
            let contentAuthor = "Author: \(pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown")"
            let contentPages = "Pages: \(pdfDocument.pageCount)\n"
            
            let contentCutoffDescription = "\(contentTitle) \(contentAuthor)"
            
            let contentPDFDescription = "\n" + contentTitle + "\n" + contentAuthor + "\n" + contentPages + "\n"

            var content = "\n\(contentCutoffDescription) PDF DOCUMENT START\n" + contentPDFDescription
            
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i) {
                    content += "\nPAGE \(i + 1) START \n"
                    
                    if let pageContent = page.string {
                        content += pageContent
                    }
                    
                    // Image preservation.
                    let annotations = page.annotations
                    for annotation in annotations {
                        if annotation.type == PDFAnnotationSubtype.stamp.rawValue {
                            content += "\n[IMAGE DETECTED]\n"
                        }
                    }
                    
                    content += "\nPAGE \(i + 1) END\n"
                }
            }

            content += "\n\n" + contentCutoffDescription + "\n\n" + invalidWebpageInstruction + "\nPDF DOCUMENT END\n"
            
            let tempPdfTextFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(websiteUrl.lastPathComponent)
                .appendingPathExtension("txt")
            
            try content.write(to: tempPdfTextFile, atomically: true, encoding: .utf8)
            #if DEBUG
            let fileSize = try FileManager.default.attributesOfItem(atPath: tempPdfTextFile.path)[.size] as? Int ?? 0
            print("Debug: Size of tempPDFTextFile is \(fileSize) bytes")
            #endif

            do {
                try FileManager.default.removeItem(at: tempPdfUrl)
            } catch {
                #if DEBUG
                print("Failed to delete temporary PDF file: \(error)")
                #endif
            }
            
            let pdfTitle = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? ""
            
            var websiteTitle = websiteUrl.host() ?? websiteUrl.absoluteString
            if !pdfTitle.isEmpty { websiteTitle = "\(pdfTitle) - \(websiteTitle)" }
            
            return (tempPdfTextFile, websiteTitle)
        } else {
            throw FetchingError.failedRequest(
                message: "Could not read PDF content from URL: \(websiteUrl)"
            )
        }
    }
    
    @MainActor
    private static func fetchHTMLContent(websiteUrl: URL, invalidWebpageInstruction: String) async throws -> (URL, String) {
        return try await withCheckedThrowingContinuation { continuation in
            // Create a visible webView for debugging
            let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
            if let window = NSApplication.shared.windows.first {
                window.contentView?.addSubview(webView)
            }
            
            let navigationDelegate = WebViewNavigationDelegate(websiteUrl: websiteUrl, invalidWebpageInstruction: invalidWebpageInstruction, completion: { result in
                // Remove the webView when done
                Task { @MainActor in
                    webView.removeFromSuperview()
                }
                continuation.resume(with: result)
            })
            webView.navigationDelegate = navigationDelegate
            
            // Set a timeout in case the page never finishes loading
            let task = Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                if !navigationDelegate.isCompleted {
                    navigationDelegate.isCompleted = true
                    // Add webView removal when timeout occurs
                    Task { @MainActor in
                        webView.removeFromSuperview()
                    }
                    continuation.resume(throwing: FetchingError.failedRequest(message: "Timeout loading webpage: \(websiteUrl)"))
                }
            }
            
            // Store task reference to cancel it when navigation completes
            navigationDelegate.timeoutTask = task
            
            let request = URLRequest(url: websiteUrl)
            webView.load(request)
        }
    }
}

// Helper class to handle navigation events
private class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    var completion: (Result<(URL, String), Error>) -> Void
    var isCompleted = false
    var timeoutTask: Task<Void, Error>?
    var websiteUrl: URL
    var invalidWebpageInstruction: String
    
    init(websiteUrl: URL, invalidWebpageInstruction: String, completion: @escaping (Result<(URL, String), Error>) -> Void) {
        self.websiteUrl = websiteUrl
        self.invalidWebpageInstruction = invalidWebpageInstruction
        self.completion = completion
        super.init()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Cancel timeout task
        timeoutTask?.cancel()
        
        // Give a small delay for any final JS to execute
        Task { @MainActor in
            // TODO replace this with dynamic loading. It should rapidly ping the page and see if new elements are being added.
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second grace period
            
            guard !isCompleted else { return }
            isCompleted = true
            
            do {
                var renderedHTML = ""
                
                if let HTML = try await webView.evaluateJavaScript("new XMLSerializer().serializeToString(document)") as? String {
                    renderedHTML = HTML
                } else if let outerHTMLFallback = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String {
                    renderedHTML = outerHTMLFallback
                } else if let innerHTMLFallback = try await webView.evaluateJavaScript("document.documentElement.innerHTML") as? String {
                    renderedHTML = innerHTMLFallback
                }
                
                do {
                    let parsedWebpageHTML = try SwiftSoup.parse(renderedHTML)
                    try parsedWebpageHTML.select("script, style, svg, video, iframe").remove()
                   
                    let headText = try parsedWebpageHTML.head()?.text() ?? ""
                    let bodyText = try parsedWebpageHTML.body()?.text() ?? ""
                   
                    var fullWebpageText = headText + "\n" + bodyText
                    if bodyText == "" {
                        fullWebpageText = "No text found for webpage with URL: \(webView.url?.absoluteString ?? "unknown")."
                    }
                    
                    let contentUrl = "URL: \(webView.url?.absoluteString ?? websiteUrl.absoluteString)"
                    let contentTitle = "Title: \(try parsedWebpageHTML.title())"
                    let contentCutoffDescription = "\(contentUrl) \(contentTitle)"
                    let contentMetaDescription = contentUrl + "\n" + contentTitle + "\n\n"
                    
                    let content = "\n\(contentCutoffDescription) WEBPAGE START\n\n" + contentMetaDescription + fullWebpageText + "\n\n" + invalidWebpageInstruction + "\n\n\(contentCutoffDescription)  WEBPAGE END\n"
                    
                    let tempHtmlTextFileUrl = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(webView.url?.host ?? "webpage")-\(UUID().uuidString)")
                        .appendingPathExtension("txt")

                    try content.write(to: tempHtmlTextFileUrl, atomically: true, encoding: .utf8)
                   
                    let websiteTitle = try parsedWebpageHTML.title()
                    let host = webView.url?.host() ?? webView.url?.absoluteString ?? websiteUrl.absoluteString
                    
                    completion(.success((tempHtmlTextFileUrl, "\(websiteTitle) - \(host)")))
                } catch {
                    completion(.failure(FetchingError.invalidResponse(
                        message: "Could not read content from URL: \(webView.url?.host() ?? webView.url?.absoluteString ?? websiteUrl.absoluteString)"
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error, webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error, webView: webView)
    }
    
    private func handleError(_ error: Error, webView: WKWebView) {
        timeoutTask?.cancel()
        
        guard !isCompleted else { return }
        isCompleted = true
        
        Task { @MainActor in
            webView.removeFromSuperview()
        }
        
        completion(.failure(FetchingError.failedRequest(
            message: "Failed to load webpage: \(webView.url?.absoluteString ?? "unknown") - \(error.localizedDescription)"
        )))
    }

}

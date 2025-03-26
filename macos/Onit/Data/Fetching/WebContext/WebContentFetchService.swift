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
    enum FetchError: Error {
        case networkError(Error)
        case parsingError(Error)
        case invalidResponse
        case contentTooLarge
    }
    
    static func fetchWebpageContent(from url: URL) async throws -> URL {
        // Check Content-Type header.
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError.invalidResponse
        }
        
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           contentType.lowercased().contains("application/pdf") {
            return try await fetchPDFContent(from: url)
        } else {
            return try await fetchHTMLContent(from: url)
        }
    }
    
    private static func fetchPDFContent(from url: URL) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FetchError.invalidResponse
        }
        
        // Limiting PDF webpage size to 50MB.
        guard data.count < 50_000_000 else {
            throw FetchError.contentTooLarge
        }
    
        // Maintaining context to the original PDF file.
        let tempPdfUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
            .appendingPathExtension("pdf")
        try data.write(to: tempPdfUrl)
        
        // Creating a structured string that's easy for the AI to parse.
        if let pdfDocument = PDFDocument(data: data) {
            var content = "PDF_DOCUMENT_START\n"
            
            content += "Title: \(pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? "Unknown")\n"
            content += "Author: \(pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown")\n"
            content += "Pages: \(pdfDocument.pageCount)\n\n"
            
            // Extract text page by page with clear separation.
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i) {
                    content += "PAGE_\(i + 1)_START\n"
                    
                    // Add page text.
                    if let pageContent = page.string {
                        content += pageContent
                    }
                    
                    // Try to preserve some structural information about images.
                    let annotations = page.annotations
                    for annotation in annotations {
                        if annotation.type == PDFAnnotationSubtype.stamp.rawValue {
                            content += "\n[IMAGE_DETECTED]\n"
                        }
                    }
                    
                    content += "\nPAGE_\(i + 1)_END\n\n"
                }
            }

            content += "PDF_DOCUMENT_END"
            
            // Create a text file with the structured string.
            let tempPdfTextFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
                .appendingPathExtension("txt")
            
            try content.write(to: tempPdfTextFile, atomically: true, encoding: .utf8)
            
            return tempPdfTextFile
        } else {
            throw FetchError.parsingError(NSError(domain: "PDFContentFetch", code: 2))
        }
    }
    
    @MainActor
    private static func fetchHTMLContent(from url: URL) async throws -> URL {
        // Load webpage with `WKWebView`.
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let request = URLRequest(url: url)
        webView.load(request)

        // Giving webpage JS content time to load (2 seconds).
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        var renderedHTML = ""
        
        if let HTML = try await webView.evaluateJavaScript("new XMLSerializer().serializeToString(document)") as? String {
            renderedHTML = HTML
        } else if let outerHTMLFallback = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String {
            renderedHTML = outerHTMLFallback
        } else if let innerHTMLFallback = try await webView.evaluateJavaScript("document.documentElement.innerHTML") as? String {
            renderedHTML = innerHTMLFallback
        }
    
        do {
            // Parse the rendered HTML (rest of your existing parsing logic)
            let parsedWebpageHTML = try SwiftSoup.parse(renderedHTML)
       
            // Remove undesired HTML tags.
            try parsedWebpageHTML.select("script, style, svg, video, iframe").remove()
           
            let headText = try parsedWebpageHTML.head()?.text() ?? ""
            let bodyText = try parsedWebpageHTML.body()?.text() ?? ""
           
            var fullWebpageText = headText + "\n" + bodyText
            if bodyText == "" {
                fullWebpageText = "No text found for webpage with URL: \(url)."
            }
            
            // Metadata.
            let contentUrl = "URL: \(url.absoluteString)"
            let contentTitle = "Title: \(try parsedWebpageHTML.title())"
            let contentCutoffDescription = "\(contentUrl) \(contentTitle)"
            let contentMetaDescription = contentUrl + "\n" + contentTitle + "\n\n"
            
            let content = "\n\n\(contentCutoffDescription) WEBPAGE START\n\n" + contentMetaDescription + fullWebpageText + "\n\n\(contentCutoffDescription)  WEBPAGE END\n\n"
            
            // Create a text file with for the non-PDF webpage.
            let tempHtmlTextFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(url.host ?? "webpage")-\(UUID().uuidString)")
                .appendingPathExtension("txt")
            try content.write(to: tempHtmlTextFile, atomically: true, encoding: .utf8)
           
            return tempHtmlTextFile
        } catch {
            throw FetchError.parsingError(error)
        }
    }
}

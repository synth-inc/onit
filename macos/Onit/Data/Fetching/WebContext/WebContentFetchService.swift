//
//  WebContentFetchService.swift
//  Onit
//
//  Created by Loyd Kim on 3/24/25.
//

import Foundation
import SwiftSoup
import PDFKit

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
    
    private static func fetchHTMLContent(from url: URL) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FetchError.invalidResponse
        }
        
        // Limiting non-PDF webpage size to 20MB.
        guard data.count < 20_000_000 else {
            throw FetchError.contentTooLarge
        }
        
        // Converting HTML to plain text
        if let htmlString = String(data: data, encoding: .utf8) {
            do {
                // Converting the non-PDF webpage contents into parsed text.
                let parsedWebpageHTML = try SwiftSoup.parse(htmlString)

                var content = "WEBPAGE_START\n"
            
                // Add metadata
                content += "URL: \(url.absoluteString)\n"
                content += "Title: \(try parsedWebpageHTML.title())\n\n"
                
                // Remove noise
                try parsedWebpageHTML.select("script, style, svg, iframe").remove()
                
                // Try to get main content
                if let article = try parsedWebpageHTML.select("article, main").first() {
                    content += try article.text()
                } else {
                    content += try parsedWebpageHTML.body()?.text() ?? ""
                }
                
                content += "\nWEBPAGE_END"
                
                // Create a text file with for the non-PDF webpage.
                let tempHtmlTextFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(url.host ?? "webpage")-\(UUID().uuidString)")
                    .appendingPathExtension("txt")

                // try webpageAsText.write(to: tempHtmlTextFile, atomically: true, encoding: .utf8)
                try content.write(to: tempHtmlTextFile, atomically: true, encoding: .utf8)
                
                return tempHtmlTextFile
            } catch {
                throw FetchError.parsingError(error)
            }
        } else {
            throw FetchError.parsingError(NSError(domain: "WebContentFetch", code: 1))
        }
    }
}

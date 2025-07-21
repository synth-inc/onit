//
//  GoogleSlidesService.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation
import GoogleSignIn

class GoogleSlidesService: GoogleDocumentServiceProtocol {

	var plainTextMimeType: String {
        return "text/plain"
    }
    
    private func readStructuredFile(fileId: String) async throws -> [String: Any] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let apiUrl = "https://slides.googleapis.com/v1/presentations/\(fileId)"
        
        guard let url = URL(string: apiUrl) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid Google Slides API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
        
        if httpResponse.statusCode == 404 {
            throw GoogleDriveServiceError.notFound("Onit needs permission to access this file.")
        } else if httpResponse.statusCode == 403 {
            var errorMessage = "Onit can't access this file."
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.accessDenied(errorMessage)
        } else if httpResponse.statusCode != 200 {
            var errorMessage = "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleDriveServiceError.decodingError("Failed to decode document content")
        }
        
        return json
    }
    
    func updateFile(fileId: String, operations: [GoogleSlidesOperation]) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://slides.googleapis.com/v1/presentations/\(fileId):batchUpdate"
        
        guard let url = URL(string: urlString) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid batchUpdate URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requests = convertToAPIRequests(operations: operations)
        let body: [String: Any] = [ "requests": requests ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
    }
    
    func convertToAPIRequests(operations: [GoogleSlidesOperation]) -> [[String: Any]] {
        var requests: [[String: Any]] = []
        
        for operation in operations {
            switch operation {
            case .insertText(let objectId, let insertionIndex, let text):
                requests.append([
                    "insertText": [
                        "objectId": objectId,
                        "insertionIndex": insertionIndex,
                        "text": text
                    ]
                ])
                
            case .deleteText(let objectId, let textRange):
                var rangeDict: [String: Any] = [:]
                if let startIndex = textRange.startIndex { rangeDict["startIndex"] = startIndex }
                if let endIndex = textRange.endIndex { rangeDict["endIndex"] = endIndex }
                if let type = textRange.type { rangeDict["type"] = type }
                
                requests.append([
                    "deleteText": [
                        "objectId": objectId,
                        "textRange": rangeDict
                    ]
                ])
                
            case .replaceAllText(let containsText, let replaceText):
                requests.append([
                    "replaceAllText": [
                        "containsText": [
                            "text": containsText,
                            "matchCase": false
                        ],
                        "replaceText": replaceText
                    ]
                ])
                
            case .createSlide(let slideLayoutReference, let insertionIndex):
                var slideRequest: [String: Any] = [:]
                
                if let layoutRef = slideLayoutReference {
                    var layoutDict: [String: Any] = [:]
                    if let layoutId = layoutRef.layoutId { layoutDict["layoutId"] = layoutId }
                    if let predefinedLayout = layoutRef.predefinedLayout { layoutDict["predefinedLayout"] = predefinedLayout }
                    slideRequest["slideLayoutReference"] = layoutDict
                }
                
                if let index = insertionIndex {
                    slideRequest["insertionIndex"] = index
                }
                
                requests.append([
                    "createSlide": slideRequest
                ])
                
            case .deleteSlide(let slideId):
                requests.append([
                    "deleteObject": [
                        "objectId": slideId
                    ]
                ])
                
            case .createShape(let slideId, let shapeType, let elementProperties):
                var shapeRequest: [String: Any] = [
                    "objectId": UUID().uuidString,
                    "shapeType": shapeType,
                    "elementProperties": [
                        "pageObjectId": elementProperties.pageObjectId
                    ]
                ]
                
                if let size = elementProperties.size {
                    shapeRequest["elementProperties"] = [
                        "pageObjectId": elementProperties.pageObjectId,
                        "size": [
                            "magnitude": size.magnitude,
                            "unit": size.unit
                        ]
                    ]
                }
                
                requests.append([
                    "createShape": shapeRequest
                ])
                
            case .createTextBox(let slideId, let elementProperties):
                requests.append([
                    "createShape": [
                        "objectId": UUID().uuidString,
                        "shapeType": "TEXT_BOX",
                        "elementProperties": [
                            "pageObjectId": elementProperties.pageObjectId,
                            "size": elementProperties.size.map { size in
                                [
                                    "magnitude": size.magnitude,
                                    "unit": size.unit
                                ]
                            } ?? [
                                "magnitude": 200,
                                "unit": "PT"
                            ]
                        ]
                    ]
                ])
                
            case .createImage(let slideId, let imageUrl, let elementProperties):
                requests.append([
                    "createImage": [
                        "objectId": UUID().uuidString,
                        "url": imageUrl,
                        "elementProperties": [
                            "pageObjectId": elementProperties.pageObjectId,
                            "size": elementProperties.size.map { size in
                                [
                                    "magnitude": size.magnitude,
                                    "unit": size.unit
                                ]
                            } ?? [
                                "magnitude": 300,
                                "unit": "PT"
                            ]
                        ]
                    ]
                ])
                
            case .updateShapeProperties(let objectId, let shapeProperties):
                var propertiesDict: [String: Any] = [:]
                
                if let backgroundFill = shapeProperties.shapeBackgroundFill {
                    propertiesDict["shapeBackgroundFill"] = [
                        "solidFill": [
                            "color": [
                                "rgbColor": [
                                    "red": 0.8,
                                    "green": 0.8,
                                    "blue": 0.8
                                ]
                            ]
                        ]
                    ]
                }
                
                requests.append([
                    "updateShapeProperties": [
                        "objectId": objectId,
                        "shapeProperties": propertiesDict,
                        "fields": propertiesDict.keys.joined(separator: ",")
                    ]
                ])
                
            case .updateTextStyle(let objectId, let textRange, let style):
                var styleDict: [String: Any] = [:]
                
                if let bold = style.bold { styleDict["bold"] = bold }
                if let italic = style.italic { styleDict["italic"] = italic }
                if let fontFamily = style.fontFamily { styleDict["fontFamily"] = fontFamily }
                if let fontSize = style.fontSize {
                    styleDict["fontSize"] = [
                        "magnitude": fontSize.magnitude,
                        "unit": fontSize.unit
                    ]
                }
                
                var rangeDict: [String: Any] = [:]
                if let range = textRange {
                    if let startIndex = range.startIndex { rangeDict["startIndex"] = startIndex }
                    if let endIndex = range.endIndex { rangeDict["endIndex"] = endIndex }
                }
                
                requests.append([
                    "updateTextStyle": [
                        "objectId": objectId,
                        "textRange": rangeDict,
                        "style": styleDict,
                        "fields": styleDict.keys.joined(separator: ",")
                    ]
                ])
                
            case .updateParagraphStyle(let objectId, let textRange, let style):
                var styleDict: [String: Any] = [:]
                
                if let alignment = style.alignment { styleDict["alignment"] = alignment }
                if let lineSpacing = style.lineSpacing { styleDict["lineSpacing"] = lineSpacing }
                
                var rangeDict: [String: Any] = [:]
                if let range = textRange {
                    if let startIndex = range.startIndex { rangeDict["startIndex"] = startIndex }
                    if let endIndex = range.endIndex { rangeDict["endIndex"] = endIndex }
                }
                
                requests.append([
                    "updateParagraphStyle": [
                        "objectId": objectId,
                        "textRange": rangeDict,
                        "style": styleDict,
                        "fields": styleDict.keys.joined(separator: ",")
                    ]
                ])
                
            case .groupObjects(let childrenObjectIds):
                requests.append([
                    "groupObjects": [
                        "childrenObjectIds": childrenObjectIds
                    ]
                ])
                
            case .ungroupObjects(let objectIds):
                for objectId in objectIds {
                    requests.append([
                        "ungroupObjects": [
                            "objectIds": [objectId]
                        ]
                    ])
                }
                
            case .duplicateObject(let objectId, let objectIds):
                requests.append([
                    "duplicateObject": [
                        "objectId": objectId,
                        "objectIds": objectIds
                    ]
                ])
            }
        }
        
        return requests
    }
    
    // MARK: - Private Helper Methods
    
    private func parseGoogleSlidesPresentation(from data: [String: Any]) throws -> GoogleSlidesPresentation {
        guard let presentationId = data["presentationId"] as? String,
              let title = data["title"] as? String,
              let slidesArray = data["slides"] as? [[String: Any]] else {
            throw GoogleDriveServiceError.invalidResponse("Invalid Google Slides structure")
        }
        
        let slides = slidesArray.compactMap { slideData in
            parseGoogleSlidesSlide(from: slideData)
        }
        
        let defaultPageSize = GoogleSlidesSize(magnitude: 720, unit: "PT")
        
        return GoogleSlidesPresentation(
            presentationId: presentationId,
            pageSize: parseGoogleSlidesSize(from: data["pageSize"] as? [String: Any]) ?? defaultPageSize,
            slides: slides,
            title: title,
            masters: nil,
            layouts: nil
        )
    }
    
    private func parseGoogleSlidesSlide(from data: [String: Any]) -> GoogleSlidesSlide? {
        guard let objectId = data["objectId"] as? String else {
            return nil
        }
        
        let pageElementsArray = data["pageElements"] as? [[String: Any]]
        let pageElements = pageElementsArray?.compactMap { parseGoogleSlidesPageElement(from: $0) }
        
        return GoogleSlidesSlide(
            objectId: objectId,
            pageElements: pageElements,
            slideProperties: parseGoogleSlidesSlideProperties(from: data["slideProperties"] as? [String: Any]),
            notesPage: nil
        )
    }
    
    private func parseGoogleSlidesPageElement(from data: [String: Any]) -> GoogleSlidesPageElement? {
        guard let objectId = data["objectId"] as? String else {
            return nil
        }
        
        let size = parseGoogleSlidesSize(from: data["size"] as? [String: Any])
        let transform = parseGoogleSlidesAffineTransform(from: data["transform"] as? [String: Any])
        
        return GoogleSlidesPageElement(
            objectId: objectId,
            size: size,
            transform: transform,
            title: data["title"] as? String,
            description: data["description"] as? String,
            shape: parseGoogleSlidesShape(from: data["shape"] as? [String: Any]),
            image: parseGoogleSlidesImage(from: data["image"] as? [String: Any]),
            video: nil, // Simplified for now
            table: nil,  // Simplified for now
            wordArt: nil, // Simplified for now
            line: nil,   // Simplified for now
            sheetsChart: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesSize(from data: [String: Any]?) -> GoogleSlidesSize? {
        guard let data = data,
              let magnitude = data["magnitude"] as? Double,
              let unit = data["unit"] as? String else {
            return nil
        }
        
        return GoogleSlidesSize(magnitude: magnitude, unit: unit)
    }
    
    private func parseGoogleSlidesAffineTransform(from data: [String: Any]?) -> GoogleSlidesAffineTransform? {
        guard let data = data else { return nil }
        
        return GoogleSlidesAffineTransform(
            scaleX: data["scaleX"] as? Double ?? 1.0,
            scaleY: data["scaleY"] as? Double ?? 1.0,
            shearX: data["shearX"] as? Double ?? 0.0,
            shearY: data["shearY"] as? Double ?? 0.0,
            translateX: data["translateX"] as? Double ?? 0.0,
            translateY: data["translateY"] as? Double ?? 0.0,
            unit: data["unit"] as? String ?? "PT"
        )
    }
    
    private func parseGoogleSlidesShape(from data: [String: Any]?) -> GoogleSlidesShape? {
        guard let data = data,
              let shapeType = data["shapeType"] as? String else {
            return nil
        }
        
        return GoogleSlidesShape(
            shapeType: shapeType,
            text: parseGoogleSlidesTextContent(from: data["text"] as? [String: Any]),
            shapeProperties: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesImage(from data: [String: Any]?) -> GoogleSlidesImage? {
        guard let data = data else { return nil }
        
        return GoogleSlidesImage(
            contentUrl: data["contentUrl"] as? String,
            imageProperties: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesTextContent(from data: [String: Any]?) -> GoogleSlidesTextContent? {
        guard let data = data,
              let textElementsArray = data["textElements"] as? [[String: Any]] else {
            return nil
        }
        
        let textElements = textElementsArray.compactMap { parseGoogleSlidesTextElement(from: $0) }
        
        return GoogleSlidesTextContent(
            textElements: textElements,
            lists: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesTextElement(from data: [String: Any]) -> GoogleSlidesTextElement? {
        let startIndex = data["startIndex"] as? Int
        let endIndex = data["endIndex"] as? Int
        
        return GoogleSlidesTextElement(
            endIndex: endIndex ?? 0,
            startIndex: startIndex,
            paragraphMarker: nil, // Simplified for now
            textRun: parseGoogleSlidesTextRun(from: data["textRun"] as? [String: Any]),
            autoText: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesTextRun(from data: [String: Any]?) -> GoogleSlidesTextRun? {
        guard let data = data,
              let content = data["content"] as? String else {
            return nil
        }
        
        return GoogleSlidesTextRun(
            content: content,
            style: nil // Simplified for now
        )
    }
    
    private func parseGoogleSlidesSlideProperties(from data: [String: Any]?) -> GoogleSlidesSlideProperties? {
        guard let data = data else { return nil }
        
        return GoogleSlidesSlideProperties(
            layoutObjectId: data["layoutObjectId"] as? String,
            masterObjectId: data["masterObjectId"] as? String,
            notesPage: nil // Simplified for now
        )
    }
} 

//
//  GoogleDocumentServiceFactory.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation
import GoogleSignIn

class GoogleDocumentServiceFactory {

	static func createService(for fileId: String) async throws -> GoogleDocumentServiceProtocol {
        let mimeType = try await getMimeType(for: fileId)
		
        switch mimeType {
        case .docs:
            return GoogleDocsService()
        case .sheet:
            return GoogleSheetsService()
        case .slide:
            return GoogleSlidesService()
        default:
            throw GoogleDriveServiceError.invalidUrl("Unsupported MIME type: \(mimeType.rawValue)")
        }
    }
    
    private static func getMimeType(for fileId: String) async throws -> GoogleDocumentMimeType {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://www.googleapis.com/drive/v3/files/\(fileId)?fields=mimeType"
        
        guard let url = URL(string: urlString) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid Google Drive API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveServiceError.invalidResponse("Failed to get file metadata")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let mimeTypeString = json?["mimeType"] as? String,
              let mimeType = GoogleDocumentMimeType(rawValue: mimeTypeString) else {
            throw GoogleDriveServiceError.invalidResponse("Unknown or unsupported MIME type")
        }
        
        return mimeType
    }
} 

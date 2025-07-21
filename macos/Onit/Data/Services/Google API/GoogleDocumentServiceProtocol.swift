//
//  GoogleDocumentServiceProtocol.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation
import GoogleSignIn

protocol GoogleDocumentServiceProtocol {
    func getPlainTextContent(fileId: String) async throws -> String
	func applyDiffChanges(fileId: String, diffChanges: [DiffChangeData]) async throws
    var plainTextMimeType: String { get }
}

extension GoogleDocumentServiceProtocol {
    
    func getPlainTextContent(fileId: String) async throws -> String {
        guard var user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        do {
            user = try await user.refreshTokensIfNeeded()
        } catch {
            print("Token refresh was unsuccessful: \(error)")
        }
        
        let accessToken = user.accessToken.tokenString
        let exportUrl = "https://www.googleapis.com/drive/v3/files/\(fileId)/export?mimeType=\(plainTextMimeType)"
        
        guard let url = URL(string: exportUrl) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid export URL")
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
            var extractionError = "Onit can't access this file."
            
            if let errorMessage = await GoogleDriveService.extractApiErrorMessage(from: data) {
                extractionError += "\n\nError message: \(errorMessage)"
            }
            
            throw GoogleDriveServiceError.accessDenied(extractionError)
        } else if httpResponse.statusCode != 200 {
            var extractionError = "Failed to retrieve document"
            
            if let errorMessage = await GoogleDriveService.extractApiErrorMessage(from: data) {
                extractionError += "\n\nError message: \(errorMessage)"
            }
            
            throw GoogleDriveServiceError.httpError(httpResponse.statusCode, extractionError)
        }
        
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func applyDiffChanges(fileId: String, diffChanges: [DiffChangeData]) async throws {
        throw GoogleDriveServiceError.unsupportedFileType("Diff changes application not implemented for this document type")
    }
}

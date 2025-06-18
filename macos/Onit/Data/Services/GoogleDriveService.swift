//
//  GoogleDriveService.swift
//  Onit
//
//  Created by Jay Swanson on 6/17/25.
//

import Foundation
import GoogleSignIn
import SwiftUI

@MainActor
class GoogleDriveService: ObservableObject {

    static let shared = GoogleDriveService()

//    func init() {
//        GIDSignIn.sharedInstance.restorePreviousSignIn()
//    }

    // Auth states
    @Published var isAuthorized = false
    @Published var userEmail: String?
    @Published var isAuthorizing = false
    @Published var isDisconnecting = false
    @Published var authorizationError: String?

    // Extraction states
    @Published var extractedText: String?
    @Published var isExtracting = false
    @Published var extractionError: String?

    func checkAuthorizationStatus() -> Bool {
        guard let googleUser = GIDSignIn.sharedInstance.currentUser else {
            self.isAuthorized = false
            self.userEmail = nil
            return false
        }

        if let grantedScopes = googleUser.grantedScopes,
            grantedScopes.contains("https://www.googleapis.com/auth/drive.file")
        {
            self.isAuthorized = true
            self.userEmail = googleUser.profile?.email
            return true
        } else {
            self.isAuthorized = false
            self.userEmail = nil
            return false
        }
    }

    func authorizeGoogleDrive() {
        self.isAuthorizing = true
        self.authorizationError = nil

        guard let window = NSApp.keyWindow else {
            print("Couldn't get key window")
            self.isAuthorizing = false
            return
        }

        let completion: (GIDSignInResult?, Error?) -> Void = { result, error in
            self.handleAuthorizationResult(result: result, error: error)
        }

        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            googleUser.addScopes(
                ["https://www.googleapis.com/auth/drive.file"],
                presenting: window,
                completion: completion
            )
        } else {
            GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: ["https://www.googleapis.com/auth/drive.file"],
                completion: completion
            )
        }
    }

    private func handleAuthorizationResult(result: GIDSignInResult?, error: Error?) {
        guard let result = result else {
            if let error = error as? NSError, error.domain == "com.google.GIDSignIn",
                error.code == -5
            {
                // The user canceled the auth flow
                self.isAuthorizing = false
                return
            } else if let error = error {
                self.authorizationError = error.localizedDescription
                self.isAuthorizing = false
            } else {
                self.authorizationError = "Unknown Google auth error"
                self.isAuthorizing = false
            }
            return
        }

        self.isAuthorized = true
        self.userEmail = result.user.profile?.email
        self.authorizationError = nil
        self.isAuthorizing = false
    }

    func disconnectGoogleDrive() {
        self.isDisconnecting = true
        self.authorizationError = nil

        GIDSignIn.sharedInstance.disconnect { error in
            Task { @MainActor in
                if let error = error {
                    let errorMsg = error.localizedDescription

                    self.authorizationError = errorMsg
                    self.isDisconnecting = false
                    return
                }

                self.isAuthorized = false
                self.userEmail = nil
                self.authorizationError = nil
                self.isDisconnecting = false
            }
        }
    }

    func extractTextFromGoogleDrive(driveUrl: String) async throws -> String {
        self.isExtracting = true
        self.extractionError = nil

        guard !driveUrl.isEmpty else {
            let error = "Please enter a Google Drive URL"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveError.invalidUrl(error)
        }

        // Extract file ID from Google Drive URL
        guard let fileId = extractFileIdFromUrl(driveUrl) else {
            let error = "Invalid Google Drive URL format"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveError.invalidUrl(error)
        }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            let error = "Not authenticated with Google Drive"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveError.notAuthenticated(error)
        }

        // Get the access token (tokens are automatically refreshed by Google Sign-In SDK)
        let accessToken = user.accessToken.tokenString

        // Determine document type and appropriate MIME type for export
        let mimeType = getMimeTypeForUrl(driveUrl)

        // Use Google Drive API to export the document
        let exportUrl =
            "https://www.googleapis.com/drive/v3/files/\(fileId)/export?mimeType=\(mimeType)"

        guard let url = URL(string: exportUrl) else {
            let error = "Invalid export URL"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveError.invalidUrl(error)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            self.isExtracting = false

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = "Invalid response"
                self.extractionError = error
                throw GoogleDriveError.invalidResponse(error)
            }

            if httpResponse.statusCode == 403 {
                var errorMessage = "Access denied. Make sure the document is publicly accessible or you have permission to view it."
                if let errorData = String(data: data, encoding: .utf8) {
                    errorMessage += "\n\nError message: \(errorData)"
                }
                self.extractionError = errorMessage
                throw GoogleDriveError.accessDenied(errorMessage)
            } else if httpResponse.statusCode != 200 {
                let error = "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
                self.extractionError = error
                throw GoogleDriveError.httpError(httpResponse.statusCode, error)
            }

            guard let text = String(data: data, encoding: .utf8) else {
                let error = "Failed to decode document content"
                self.extractionError = error
                throw GoogleDriveError.decodingError(error)
            }

            if text.isEmpty {
                return "(Document appears to be empty)"
            } else {
                return text
            }
        } catch {
            let errorMessage = "Network error: \(error.localizedDescription)"
            self.extractionError = errorMessage
            self.isExtracting = false
            throw GoogleDriveError.networkError(errorMessage)
        }
    }

    private func getMimeTypeForUrl(_ url: String) -> String {
        if url.contains("docs.google.com/document") {
            return "text/plain"
        } else if url.contains("docs.google.com/spreadsheets") {
            return "text/csv"
        } else if url.contains("docs.google.com/presentation") {
            return "text/plain"
        } else {
            // Default to text/plain for generic drive URLs
            return "text/plain"
        }
    }

    private func extractFileIdFromUrl(_ url: String) -> String? {
        // Handle various Google Drive URL formats
        let patterns = [
            #"https://docs\.google\.com/document/d/([a-zA-Z0-9-_]+)"#,
            #"https://drive\.google\.com/file/d/([a-zA-Z0-9-_]+)"#,
            #"https://docs\.google\.com/spreadsheets/d/([a-zA-Z0-9-_]+)"#,
            #"https://docs\.google\.com/presentation/d/([a-zA-Z0-9-_]+)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
                let match = regex.firstMatch(
                    in: url, range: NSRange(location: 0, length: url.count)),
                let fileIdRange = Range(match.range(at: 1), in: url)
            {
                return String(url[fileIdRange])
            }
        }

        return nil
    }

    
}

enum GoogleDriveError: Error, LocalizedError {
    case notAuthenticated(String)
    case networkError(String)
    case decodingError(String)
    case authorizationError(String)
    case fileNotFound(String)
    case invalidUrl(String)
    case extractionError(String)
    case unsupportedFileType(String)
    case invalidFileId(String)
    case httpError(Int, String)
    case accessDenied(String)
    case invalidResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated(let message):
            return "Not Authenticated: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .decodingError(let message):
            return "Decoding Error: \(message)"
        case .authorizationError(let message):
            return "Authorization Error: \(message)"
        case .fileNotFound(let message):
            return "File Not Found: \(message)"
        case .invalidUrl(let message):
            return "Invalid URL: \(message)"
        case .extractionError(let message):
            return "Extraction Error: \(message)"
        case .unsupportedFileType(let message):
            return "Unsupported File Type: \(message)"
        case .invalidFileId(let message):
            return "Invalid File ID: \(message)"
        case .httpError(let code, let message):
            return "HTTP Error (\(code)): \(message)"
        case .accessDenied(let message):
            return "Access Denied: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        }
    }
}

//
//  GoogleDocumentManager.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation

class GoogleDocumentManager {
    
    static func readPlainText(fileId: String) async throws -> String {
        let service = try await GoogleDocumentServiceFactory.createService(for: fileId)

        return try await service.getPlainTextContent(fileId: fileId)
    }
    
    static func applyDiffChangesToDocument(
        documentUrl: String,
        diffChanges: [DiffChangeData]
    ) async throws {
        guard let fileId = await GoogleDriveService.extractFileId(from: documentUrl) else {
            throw GoogleDriveError.invalidUrl("Could not extract file ID from URL: \(documentUrl)")
        }
        
        let approvedChanges = diffChanges.filter { $0.status == .approved }
        guard !approvedChanges.isEmpty else {
            return
        }
        
        let service = try await GoogleDocumentServiceFactory.createService(for: fileId)

        try await service.applyDiffChanges(fileId: fileId, diffChanges: approvedChanges)
    }
}

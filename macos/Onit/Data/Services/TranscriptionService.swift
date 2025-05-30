//
//  TranscriptionService.swift
//  Onit
//
//  Created by Jay Swanson on 5/30/25.
//

import Foundation

class TranscriptionService {
    private let endpoint = "\(OnitServer.baseURL)/v1/chat/transcription"
    
    func transcribe(audioURL: URL) async throws -> String {
        let boundary = UUID().uuidString
        guard let url = URL(string: endpoint) else { throw FetchingError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(TokenManager.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add file data
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: audioURL))
        data.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse(message: "Invalid response")
        }
        if !(200...299).contains(httpResponse.statusCode) {
            let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw FetchingError.invalidResponse(message: message)
        }
        let responseDecoded = try JSONDecoder().decode(TranscriptionResponse.self, from: responseData)
        return responseDecoded.text
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}

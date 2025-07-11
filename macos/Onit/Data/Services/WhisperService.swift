import Defaults
import Foundation

class WhisperService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/audio/transcriptions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        let boundary = UUID().uuidString
        guard let url = URL(string: endpoint) else { throw FetchingError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add model parameter
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8),
              let whisperData = "whisper-1\r\n".data(using: .utf8)
        else {
            throw FetchingError.invalidResponse(message: "Failed to encode model parameters")
        }
        
        data.append(boundaryData)
        data.append(dispositionData)
        data.append(whisperData)
        
        // Configuring Whisper API to return `no_speech_prob`.
        guard let responseFormatBoundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let responseDispositionData = "Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8),
              let responseFormatData = "verbose_json\r\n".data(using: .utf8)
        else {
            throw FetchingError.invalidResponse(message: "Failed to encode response_format parameter")
        }
        
        data.append(responseFormatBoundaryData)
        data.append(responseDispositionData)
        data.append(responseFormatData)
        
        // Add file data
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8),
              let contentTypeData = "Content-Type: audio/m4a\r\n\r\n".data(using: .utf8),
              let newlineData = "\r\n".data(using: .utf8),
              let closingBoundaryData = "--\(boundary)--\r\n".data(using: .utf8)
        else {
            throw FetchingError.invalidResponse(message: "Failed to encode multipart form data")
        }
        
        data.append(boundaryData)
        data.append(dispositionData)
        data.append(contentTypeData)
        data.append(try Data(contentsOf: audioURL))
        data.append(newlineData)
        data.append(closingBoundaryData)
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse(message: "Invalid response")
        }
        if !(200...299).contains(httpResponse.statusCode) {
            let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw FetchingError.invalidResponse(message: message)
        }
        
        let decoder = JSONDecoder()
        let responseDecoded = try decoder.decode(WhisperServiceVerbose.self, from: responseData)
        
        let transcribedText = responseDecoded.segments.filter { segment in
            let speechConfidence = 1 - segment.no_speech_prob
            let passesSpeechPassThreshold = speechConfidence >= Defaults[.voiceSpeechPassThreshold]
            return passesSpeechPassThreshold
        }
            .map { $0.text }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return transcribedText
    }
}

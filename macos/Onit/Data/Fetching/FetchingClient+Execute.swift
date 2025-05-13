//
//  FetchingClient+Execute.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension FetchingClient {
    func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        var url = endpoint.baseURL.appendingPathComponent(endpoint.path)

        if let getParams = endpoint.getParams {
            if !getParams.isEmpty {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems = getParams.map {
                    URLQueryItem(name: $0.key, value: $0.value)
                }
                if let updatedURL = urlComponents?.url {
                    url = updatedURL
                }
            }
        }

        var requestBodyData: UploadBody = .empty
        if let requestBody = endpoint.requestBody {
            let data = try encoder.encode(requestBody)
            requestBodyData = .data(data)
        }

        // Helpful debugging method- put in the endpoint name and you can see the full request
        if endpoint.baseURL.absoluteString.contains("api.perplexity.ai") {
            FetchingClient.printCurlRequest(endpoint: endpoint, url: url)
            print("here")
        }

        do {
            let data = try await self.data(
                from: url,
                method: endpoint.method,
                body: requestBodyData,
                contentType: "application/json",
                token: endpoint.token,
                additionalHeaders: endpoint.additionalHeaders,
                timeout: endpoint.timeout
            )

            if let data = data {
                let decodedResponse = try decoder.decode(E.Response.self, from: data)
                return decodedResponse
            // This is testing if the Response in the Endpoint definition is optional
            // If it's optional and no data was returned from the endpoint, return that optional
            } else if let optional = Optional<Any>.none as? E.Response {
                return optional
            } else {
                throw FetchingError.noContent
            }
        } catch let error as DecodingError {
            throw FetchingError.decodingError(error)
        } catch {
            throw error
        }
    }

    func executeMultipart<E: Endpoint>(_ endpoint: E, files: [URL]) async throws -> E.Response {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let token = endpoint.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = try createMultipartBody(for: endpoint, files: files, boundary: boundary)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        let message = parseErrorMessage(from: data) ?? "Client error occurred."
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse(message: message)
        }
        try self.handle(response: httpResponse, withData: data)
        let decodedResponse = try decoder.decode(E.Response.self, from: data)
        return decodedResponse
    }

    private func createMultipartBody<E: Endpoint>(for endpoint: E, files: [URL], boundary: String)
        throws -> Data
    {
        var body = Data()

        if let requestBody = endpoint.requestBody {
            let jsonData = try encoder.encode(requestBody)
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                for (key, value) in jsonDict {
                    if let stringValue = value as? String, stringValue.isEmpty {
                        continue
                    } else if value is NSNull {
                        continue
                    }

                    body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
                    body.append(
                        "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)
                            ?? Data())

                    let valueString: String
                    if let stringValue = value as? String {
                        valueString = stringValue
                    } else if let boolValue = value as? Bool {
                        valueString = boolValue ? "true" : "false"
                    } else {
                        let valueData = try JSONSerialization.data(withJSONObject: value)
                        valueString = String(data: valueData, encoding: .utf8) ?? ""
                    }

                    body.append(valueString.data(using: .utf8) ?? Data())
                    body.append("\r\n".data(using: .utf8) ?? Data())
                }
            }
        }

        for fileURL in files {
            let fileName = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
            body.append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(
                    using: .utf8) ?? Data())
            body.append(
                "Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8) ?? Data())
            body.append(fileData)
            body.append("\r\n".data(using: .utf8) ?? Data())
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        return body
    }


}

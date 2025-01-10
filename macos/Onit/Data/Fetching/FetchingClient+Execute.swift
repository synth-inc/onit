//
//  FetchingClient+Execute.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension FetchingClient {
    func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)

        var requestBodyData: UploadBody = .empty
        if let requestBody = endpoint.requestBody {
            let data = try encoder.encode(requestBody)
            requestBodyData = .data(data)
        }

        printCurlRequest(endpoint: endpoint, url: url)

        do {
            let data = try await self.data(
                from: url,
                method: endpoint.method,
                body: requestBodyData,
                contentType: "application/json",
                token: endpoint.token,
                additionalHeaders: endpoint.additionalHeaders
            )
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON Response:")
                print(jsonString)
            } else {
                print("Failed to convert data to JSON string.")
            }
            let decodedResponse = try decoder.decode(E.Response.self, from: data)
            return decodedResponse
        } catch let error as DecodingError {
            throw FetchingError.decodingError(error)
        } catch {
            throw error
        }
    }

    func executeSSE<E: Endpoint>(_ endpoint: E, onEvent: @Sendable @escaping (E.Response) -> Void, onError: @Sendable @escaping (Error) -> Void) async throws {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let token = endpoint.token {
            // request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addAuthorization(token: token)
        }

        // TODO this should go in the endpoints themselves
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        var requestBodyData: UploadBody = .empty
        if let requestBody = endpoint.requestBody {
            let data = try encoder.encode(requestBody)
            requestBodyData = .data(data)
        }
        if case let .data(data) = requestBodyData {
            request.httpBody = data
        }
        request.addContentType(for: endpoint.method, defaultType: "application/json")
        endpoint.additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        printCurlRequest(endpoint: endpoint, url: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                onError(error)
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                onError(FetchingError.invalidResponse)
                return
            }

            // This seems nuts. Is this really the best way?
            // There are so many uncaught errors here. Lot's of potential to fail silently.
            // TODO: look into SSE in Swift
            let events = String(data: data, encoding: .utf8)?.components(separatedBy: "\n\n") ?? []
            for event in events {
                if let eventData = event.data(using: .utf8) {
                    if let eventDataString = String(data: eventData, encoding: .utf8) {
                        let lines = eventDataString.split(separator: "\n")
                        for line in lines {
                            let components = line.split(separator: ":", maxSplits: 1)
                            if components.count == 2, components[0].trimmingCharacters(in: .whitespaces) == "data" {
                                let dataPart = components[1].trimmingCharacters(in: .whitespaces)
                                if let data = dataPart.data(using: .utf8) {
                                    do {
                                        let decodedEvent = try self.decoder.decode(E.Response.self, from: data)
                                        onEvent(decodedEvent)
                                    } catch {
                                        onError(FetchingError.decodingError(error as! DecodingError))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        task.resume()
    }

    func executeMultipart<E: Endpoint>(_ endpoint: E, files: [URL]) async throws -> E.Response {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let token = endpoint.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = try createMultipartBody(for: endpoint, files: files, boundary: boundary)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse
        }
        try self.handle(response: httpResponse, withData: data)
        let decodedResponse = try decoder.decode(E.Response.self, from: data)
        return decodedResponse
    }

    private func createMultipartBody<E: Endpoint>(for endpoint: E, files: [URL], boundary: String) throws -> Data {
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
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) ?? Data())

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
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) ?? Data())
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8) ?? Data())
            body.append(fileData)
            body.append("\r\n".data(using: .utf8) ?? Data())
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        return body
    }

    private func printCurlRequest<E: Endpoint>(endpoint: E, url: URL) {
        if let requestBody = endpoint.requestBody {
            if let jsonData = try? encoder.encode(requestBody),
                let jsonString = String(data: jsonData, encoding: .utf8) {
                print("CURL Request:")
                print("curl -X \(endpoint.method.rawValue) \(url.absoluteString) \\")
                print("  -H 'Content-Type: application/json' \\")
                if let token = endpoint.token {
                    print("  -H 'Authorization: Bearer \(token)' \\")
                }
                if let additionalHeaders = endpoint.additionalHeaders {
                    for (header, value) in additionalHeaders {
                        print("  -H '\(header): \(value)' \\")
                    }
                }
                print("  -d '\(jsonString)'")
            }
        }
    }
}

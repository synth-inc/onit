//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Foundation
import PhotosUI

extension FetchingClient {
    func localChat(_ text: String, input: Input?, model: LocalModel?, files: [URL], images: [URL]) async throws -> String {
        // TODO we should just leave the images local. 
        var base64Strings: [String] = []
        for image in images {
            if let imageData = try? Data(contentsOf: image) {
                if let nsImage = NSImage(data: imageData) {
                    if let base64String = nsImage.base64String() {
                        base64Strings.append(base64String)
                    } else {
                        print("Failed to convert image to base64 string at URL: \(image)")
                    }
                } else {
                    print("Failed to create NSImage from data at URL: \(image)")
                }
            } else {
                print("Failed to download image data from URL: \(image)")
            }
        }

        let endpoint = LocalChatEndpoint(model: model, prompt: text, images: base64Strings)
        let response = try await {
            if files.isEmpty {
                try await execute(endpoint)
            } else {
                try await executeMultipart(endpoint, files: files)
            }
        }()
        return response.response
    }
}

struct LocalChatEndpoint: Endpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalChatRequestJSON
    typealias Response = LocalChatResponseJSON

    let model: LocalModel?
    let prompt: String
    let images: [String]
    var baseURL: URL  = URL(string: "http://localhost:11434")!
    
    var path: String { "/api/generate" }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var requestBody: LocalChatRequestJSON? {
        LocalChatRequestJSON(model: model, prompt: prompt, images: images)
    }
}

// TODO change this to match the expected request
struct LocalChatRequestJSON: Codable {
    let model: LocalModel?
    let prompt: String
    let images: [String]
//    var format : String = "json"
    var stream : Bool = false
}

struct LocalChatResponseJSON: Codable {
    let response: String
}

//
//  LLMRequest.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//


import Foundation

struct LLMRequest {
    let instructions: [String]
    let inputs: [Input?]
    let files: [[URL]]
    let images: [[URL]]
    let autoContexts: [[String: String]]
    let responses: [String]
    let model: AIModel?
}

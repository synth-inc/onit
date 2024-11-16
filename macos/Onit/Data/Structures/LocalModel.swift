//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Foundation

enum LocalModel: String, CaseIterable, Codable {
    case llama32_1b = "llama3.2:1b"
    case llama32 = "llama3.2"
    case llama32_vision_11b = "llama3.2-vision"
    case llama32_vision_90b = "llama3.2-vision:90b"
    case llama31_8b = "llama3.1"
    case llama31_70b = "llama3.1:70b"
    case llama31_405b = "llama3.1:405b"
    case phi3_mini = "phi3"
    case phi3_medium = "phi3:medium"
    case gemma2_2b = "gemma2:2b"
    case gemma2_9b = "gemma2"
    case gemma2_27b = "gemma2:27b"
    case mistral = "mistral"
    case moondream2 = "moondream"
    case neural_chat = "neural-chat"
    case starling = "starling-lm"
    case code_llama = "codellama"
    case llama2_uncensored = "llama2-uncensored"
    case llava = "llava"
    case solar = "solar"
}

extension LocalModel: Identifiable {
    var id: RawValue { self.rawValue }
}


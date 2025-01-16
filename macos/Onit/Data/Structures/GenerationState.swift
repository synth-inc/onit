//
//  GenerationState.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

enum GenerationState: Equatable, Codable {
    case idle
    case generating
    case generated
    case error(FetchingError)
    
    enum CodingKeys: String, CodingKey {
        case type, fetchingError
    }
    
    enum GenerationStateType: String, Codable {
        case idle, generating, generated, error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GenerationStateType.self, forKey: .type)
        
        switch type {
        case .idle:
            self = .idle
        case .generating:
            self = .generating
        case .generated:
            self = .generated
        case .error:
            let error = try container.decode(FetchingError.self, forKey: .fetchingError)
            self = .error(error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .idle:
            try container.encode(GenerationStateType.idle, forKey: .type)
        case .generating:
            try container.encode(GenerationStateType.generating, forKey: .type)
        case .generated:
            try container.encode(GenerationStateType.generated, forKey: .type)
        case .error(let error):
            try container.encode(GenerationStateType.error, forKey: .type)
            try container.encode(error, forKey: .fetchingError)
        }
    }
}

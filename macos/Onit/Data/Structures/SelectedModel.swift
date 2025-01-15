//
//  SelectedModel.swift
//  Onit
//
//  Created by Benjamin Sage on 1/15/25.
//

import Foundation

enum SelectedModel: Equatable, Identifiable, Hashable {
    case remote(AIModel)
    case local(String)

    var id: String {
        switch self {
        case .remote(let aiModel):
            return "remote-\(aiModel.rawValue)"
        case .local(let localModel):
            return "local-\(localModel)"
        }
    }
}

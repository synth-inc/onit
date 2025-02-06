//
//  ServerErrorResponse.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

struct ServerErrorResponse: Decodable {
    let error: Bool
    let message: String
}

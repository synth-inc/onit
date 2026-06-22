//
//  LoginResponse.swift
//  Onit
//
//  Created by Jason Swanson on 4/22/25.
//

struct LoginResponse: Codable {
    let token: String
    let account: Account
    let isNewAccount: Bool
}

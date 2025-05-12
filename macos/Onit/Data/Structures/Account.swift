//
//  Account.swift
//  Onit
//
//  Created by Jason Swanson on 4/21/25.
//

struct Account: Codable {
    let id: Int
    let email: String?
    let googleUserId: String?
    let appleUserId: String?
    let appleEmail: String?
}

extension Account: Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.email == rhs.email
    }
}

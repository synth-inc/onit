//
//  TokenManager.swift
//  Onit
//
//  Created by Jason Swanson on 4/23/25.
//

import Foundation
import Security

struct TokenManager {
    private static let service = "inc.synth.Onit.auth"
    private static let keychainGroup = "inc.synth.Onit"
    private static let account = "token"

    public static var token: String? {
        get {
            TokenManager.fetch()
        } set {
            guard let value = newValue else {
                TokenManager.remove()
                return
            }
            TokenManager.save(token: value)
        }
    }

    @discardableResult private static func save(token: String) -> Bool {
        let data = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: keychainGroup,
            kSecValueData as String: data
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            return false
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private static func fetch() -> String? {
        // First try with access group (new format)
        let queryWithGroup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: keychainGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var out: CFTypeRef?
        let status = SecItemCopyMatching(queryWithGroup as CFDictionary, &out)

        if status == errSecSuccess {
            if let retrievedData = out as? Data,
               let token = String(data: retrievedData, encoding: .utf8) {
                return token
            }
        }

        // If not found with access group, try legacy format
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let legacyStatus = SecItemCopyMatching(legacyQuery as CFDictionary, &out)

        if legacyStatus == errSecSuccess {
            if let retrievedData = out as? Data,
               let token = String(data: retrievedData, encoding: .utf8) {
                // Found legacy token, migrate it to new format
                if save(token: token) {
                    // Remove the legacy token
                    _ = SecItemDelete(legacyQuery as CFDictionary)
                    return token
                }
            }
        }

        return nil
    }

    @discardableResult private static func remove() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

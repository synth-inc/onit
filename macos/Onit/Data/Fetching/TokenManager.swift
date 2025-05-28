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
//    private static let keychainGroup = "TYC9PKBMB6.inc.synth.Onit.dev"
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

    private static func getDefaultAccessGroup() -> String? {
        // Create a query that will match any keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let accessGroup = attributes[kSecAttrAccessGroup as String] as? String {
            print("Found default access group: \(accessGroup)")
            return accessGroup
        }
        
//        // If no existing items found, try to get it from the bundle
//        if let bundleIdentifier = Bundle.main.bundleIdentifier {
//            let defaultGroup = "\(Bundle.main.teamIdentifier ?? "").\(bundleIdentifier)"
//            print("Using bundle-derived access group: \(defaultGroup)")
//            return defaultGroup
//        }
        
        print("Could not determine default access group")
        return nil
    }

    @discardableResult private static func save(token: String) -> Bool {
        let data = Data(token.utf8)
        
        let accessGroup = getDefaultAccessGroup()
        print("Attempting to save token with access group: \(accessGroup ?? "none")")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup ?? "",
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: false
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("Failed to delete existing item: \(deleteStatus)")
            return false
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to add item: \(status)")
            return false
        }
        
        // Immediately read it out
        let accessGroup2 = getDefaultAccessGroup()
        TokenManager.fetchAndPrintAttributes()
        
        return status == errSecSuccess
    }
    
    private static func fetchAndPrintAttributes() {
//        let accessGroup = getDefaultAccessGroup()
        let queryWithGroup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
//            kSecAttrAccessGroup as String: accessGroup ?? "",
            kSecReturnData as String: false,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var out: CFTypeRef?
        let status = SecItemCopyMatching(queryWithGroup as CFDictionary, &out)
        
        // We could cehck if it has a kSecAttrAccessGroup, if not, overwrite it with one that does.
        if let attributesList = out as? [[String: Any]] {
            for attributes in attributesList {
                print("Attributes for account '\(account)':")
                for (key, value) in attributes {
                    print("  \(key): \(value)")
                }
                if let accessGroup = attributes[kSecAttrAccessGroup as String] {
                    print("  Has access group: \(accessGroup)")
                } else {
                    print("  No access group found")
                }
            }
        }
    }

    private static func fetch() -> String? {
        fetchAndPrintAttributes()
        let accessGroup = getDefaultAccessGroup()
        // First try with access group (new format)
        let queryWithGroup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup ?? "",
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
